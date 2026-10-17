using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Npgsql;
using PAO.BackgroundJobs;
using PAO.EF;
using PAO.EF.Connection;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Jobs;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Booking;
using PAO.TestKit;

namespace PAO.IntegrationTests;

public sealed class OutboxTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private NpgsqlDataSource dataSource = null!;
    private IDbContextFactory<PaoDbContext> contexts = null!;
    private readonly FakeClock clock = new(DateTimeOffset.UtcNow);
    private readonly WorkerMetrics metrics = new PaoMetrics().Worker;

    public async ValueTask InitializeAsync()
    {
        dataSource = PaoDbContextSetup.CreateDataSource(PostgresUrl.ToConnectionString(database.Url));
        var options = new DbContextOptionsBuilder<PaoDbContext>();
        PaoDbContextSetup.Configure(options, dataSource);
        contexts = new TestContextFactory(options.Options);
        await Execute("DELETE FROM booking.outbox; DELETE FROM rating.processed_events");
    }

    public async ValueTask DisposeAsync() => await dataSource.DisposeAsync();

    private async Task Execute(string sql)
    {
        await using var command = dataSource.CreateCommand(sql);
        await command.ExecuteNonQueryAsync();
    }

    private async Task<object?> Scalar(string sql)
    {
        await using var command = dataSource.CreateCommand(sql);
        return await command.ExecuteScalarAsync();
    }

    private async Task Write(string aggregate)
    {
        await using var db = await contexts.CreateDbContextAsync();
        await using var tx = await db.Database.BeginTransactionAsync();
        await new OutboxWriter(new PAO.Infrastructure.Data.UuidV7Generator(), clock).Write(db, "booking", aggregate, new BookingAccepted
        {
            BookingId = Guid.NewGuid(), Number = "B-1", CustomerId = Guid.NewGuid(), ProviderId = Guid.NewGuid(), ServiceId = Guid.NewGuid(), At = "2026-10-17T00:00:00Z",
        }, CancellationToken.None);
        await tx.CommitAsync();
    }

    private OutboxRelay Relay(IEventDispatcher bus) => new(dataSource, bus, ["booking", "rating"], clock, metrics, NullLogger<OutboxRelay>.Instance);

    [Fact]
    public async Task Relays_in_order_retries_with_backoff_and_dead_letters()
    {
        await Write("a");
        await Write("a");
        await Write("b");
        var bus = new EventBus();
        var seen = new List<string>();
        var failA = true;
        bus.Subscribe(BookingEvents.BookingAccepted, "test", (e, _) =>
        {
            if (e.AggregateId == "a" && failA)
            {
                throw new InvalidOperationException("down");
            }
            seen.Add(e.AggregateId + new EventPayload(e).Text("number"));
            return Task.CompletedTask;
        });
        Assert.Equal(1, await Relay(bus).RunOnce(CancellationToken.None));
        Assert.Equal(["bB-1"], seen);
        Assert.Equal(0, await Relay(bus).RunOnce(CancellationToken.None));
        failA = false;
        clock.Advance(TimeSpan.FromSeconds(3));
        Assert.Equal(2, await Relay(bus).RunOnce(CancellationToken.None));
        await Write("c");
        await Execute("UPDATE booking.outbox SET attempts = 9 WHERE aggregate_id = 'c'");
        failA = true;
        await Execute("UPDATE booking.outbox SET aggregate_id = 'a' WHERE aggregate_id = 'c'");
        Assert.Equal(0, await Relay(bus).RunOnce(CancellationToken.None));
        Assert.Equal(1L, await Scalar("SELECT count(*) FROM booking.outbox WHERE dead"));
        var backlog = await new OutboxMaintenance(dataSource, ["booking", "rating"]).Backlog(clock.Now, CancellationToken.None);
        Assert.Equal(new OutboxBacklog("rating", 0, 0, 0), backlog[1]);
        Assert.Equal(1, backlog[0].Dead);
    }

    [Fact]
    public async Task Purges_old_deliveries_and_reports_the_backlog()
    {
        await Write("p");
        var maintenance = new OutboxMaintenance(dataSource, ["booking"]);
        var backlog = await maintenance.Backlog(clock.Now.AddSeconds(5), CancellationToken.None);
        Assert.Equal(1, backlog[0].Pending);
        Assert.Equal(5, backlog[0].OldestSeconds, 1);
        await Execute("UPDATE booking.outbox SET published_at = now() - interval '8 days'");
        var job = new OutboxPurgeJob(maintenance, new FakeClock(DateTimeOffset.UtcNow), Options.Create(new JobsOptions()));
        Assert.Equal("outbox.purge_published", job.Name);
        Assert.Equal(JobSchedule.DailyAt(3, 0), job.Schedule);
        await job.Run(CancellationToken.None);
        Assert.Equal(0L, await Scalar("SELECT count(*) FROM booking.outbox"));
    }

    [Fact]
    public async Task Idempotent_handlers_apply_an_event_once()
    {
        var applied = 0;
        var handler = new IdempotentEventHandler(contexts).Wrap("rating", "rating.test", (_, _, _) => { applied++; return Task.CompletedTask; });
        var envelope = new Envelope
        {
            Id = Guid.NewGuid(), Module = "booking", Name = "x", AggregateId = "a",
            Payload = System.Text.Json.JsonDocument.Parse("{}").RootElement, OccurredAt = clock.Now,
        };
        await handler(envelope, CancellationToken.None);
        await handler(envelope, CancellationToken.None);
        Assert.Equal(1, applied);
    }

    private sealed class Job(string name, Func<Task> run) : IScheduledJob
    {
        public string Name => name;

        public JobSchedule Schedule { get; } = JobSchedule.Every(TimeSpan.FromMilliseconds(1));

        public Task Run(CancellationToken cancellationToken) => run();
    }

    [Fact]
    public async Task The_scheduler_runs_each_job_under_its_advisory_lock()
    {
        var runs = 0;
        var ok = new Job("test.ok", () => { runs++; return Task.CompletedTask; });
        var broken = new Job("test.broken", () => throw new InvalidOperationException("boom"));
        var scheduler = new JobScheduler(dataSource, [ok, broken], clock, metrics, NullLogger<JobScheduler>.Instance);
        Assert.True(await scheduler.RunNow(ok, CancellationToken.None));
        Assert.True(await scheduler.RunNow(broken, CancellationToken.None));
        await using (var holder = await dataSource.OpenConnectionAsync())
        {
            await using var lockIt = new NpgsqlCommand("SELECT pg_advisory_lock(7041, hashtext('test.ok'))", holder);
            await lockIt.ExecuteNonQueryAsync();
            Assert.False(await scheduler.RunNow(ok, CancellationToken.None));
        }
        Assert.Equal(1, runs);
        Assert.Throws<InvalidOperationException>(() => new JobScheduler(dataSource, [ok, ok], clock, metrics, NullLogger<JobScheduler>.Instance));
        using var stop = new CancellationTokenSource();
        var looping = new JobScheduler(dataSource, [ok], clock, metrics, NullLogger<JobScheduler>.Instance, (_, _) =>
        {
            if (runs >= 3)
            {
                stop.Cancel();
                throw new OperationCanceledException();
            }
            return Task.CompletedTask;
        });
        await looping.RunAll(stop.Token);
        Assert.Equal(3, runs);
        await looping.RunForever(ok, stop.Token);
    }

    [Fact]
    public async Task The_worker_loop_relays_until_stopped_and_survives_failures()
    {
        var bus = new EventBus();
        var broken = new OutboxRelay(dataSource, bus, ["nonexistent"], clock, metrics, NullLogger<OutboxRelay>.Instance);
        var options = Options.Create(new JobsOptions { OutboxRelayIntervalMs = 10 });
        var scheduler = new JobScheduler(dataSource, [], clock, metrics, NullLogger<JobScheduler>.Instance);
        using var stop = new CancellationTokenSource(TimeSpan.FromMilliseconds(200));
        await new WorkerLoop(scheduler, broken, options, NullLogger<WorkerLoop>.Instance).Relay(stop.Token);
        var loop = new WorkerLoop(scheduler, Relay(bus), options, NullLogger<WorkerLoop>.Instance);
        await loop.StartAsync(CancellationToken.None);
        await Task.Delay(50);
        await loop.StopAsync(CancellationToken.None);
    }
}
