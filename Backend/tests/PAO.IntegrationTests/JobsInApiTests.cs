using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Npgsql;
using PAO.BackgroundJobs;
using PAO.Core;
using PAO.Core.Registration;
using PAO.Infrastructure.Http;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Redis;
using PAO.Infrastructure.Registration;
using PAO.TestKit;

namespace PAO.IntegrationTests;

/// <summary>JOBS_IN_API (ADR-0036 §14): the API host built as Program.cs builds it, with and without the worker's services.</summary>
public sealed class JobsInApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>
{
    private async Task<(WebApplication App, Task<int> Running)> StartApi(bool jobsInApi)
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { ContentRootPath = AppContext.BaseDirectory });
        builder.WebHost.UseTestServer();
        var environment = Hosts.Environment(database.Url);
        environment["JOBS_IN_API"] = jobsInApi ? "true" : "false";
        var settings = builder.AddPaoSettings(Hosts.Paths, environment, "api");
        settings.Logging.WriteFiles = false;
        builder.Services
            .AddBuiltInServices(settings, Hosts.Paths.Spec, typeof(ApiHost).Assembly)
            .AddCustomServices(settings, typeof(ApiHost).Assembly)
            .AddDatabase(settings)
            .AddRepositories()
            .AddAreas()
            .AddBackgroundJobsInApi(settings, Hosts.Paths);
        builder.Services.AddSingleton(new RedisKeys(TestEnvironment.Unique("t")));
        var app = builder.Build();
        app.UseHttpEdge(settings);
        var running = app.RunApi(settings, web => web.UseTestServer());
        // Start-up checks can take longer than any fixed delay on a loaded machine.
        await Task.Delay(Timeout.Infinite, app.Lifetime.ApplicationStarted).ContinueWith(_ => { }, TaskScheduler.Default);
        return (app, running);
    }

    private static async Task Until(Func<Task<bool>> condition, string what)
    {
        // The booking expiry sweep first runs 15 s after start.
        var deadline = DateTimeOffset.UtcNow.AddSeconds(60);
        while (!await condition())
        {
            Assert.True(DateTimeOffset.UtcNow < deadline, $"timed out waiting for {what}");
            await Task.Delay(200);
        }
    }

    private static async Task<bool> Published(IServiceProvider services, Guid id)
    {
        await using var command = services.GetRequiredService<NpgsqlDataSource>()
            .CreateCommand("SELECT published_at IS NOT NULL FROM booking.outbox WHERE id = $1");
        command.Parameters.Add(new NpgsqlParameter { Value = id });
        return await command.ExecuteScalarAsync() is true;
    }

    private static async Task<string> Metrics(IServiceProvider services)
    {
        using var text = new MemoryStream();
        await services.GetRequiredService<PaoMetrics>().Registry.CollectAndExportAsTextAsync(text);
        return System.Text.Encoding.UTF8.GetString(text.ToArray());
    }

    [Fact]
    public async Task On_the_api_relays_outbox_events_and_runs_the_jobs_until_it_stops()
    {
        var (app, running) = await StartApi(jobsInApi: true);
        var loop = Assert.Single(app.Services.GetServices<IHostedService>().OfType<WorkerLoop>());
        var id = Guid.NewGuid();
        await using (var insert = app.Services.GetRequiredService<NpgsqlDataSource>().CreateCommand(
            "INSERT INTO booking.outbox (id, aggregate_id, event_name, payload) VALUES ($1, 'jobs-in-api', 'test.Unsubscribed', '{}')"))
        {
            insert.Parameters.Add(new NpgsqlParameter { Value = id });
            await insert.ExecuteNonQueryAsync();
        }
        await Until(() => Published(app.Services, id), "the relay to deliver the event");
        await Until(async () => (await Metrics(app.Services)).Contains("name=\"booking.expire_requests\",outcome=\"ok\"", StringComparison.Ordinal), "the booking expiry run");
        await app.StopAsync();
        Assert.Equal(0, await running);
        Assert.True(loop.ExecuteTask!.IsCompleted);
        await app.DisposeAsync();
    }

    [Fact]
    public async Task Off_the_api_runs_no_relay_and_no_job()
    {
        var (app, running) = await StartApi(jobsInApi: false);
        Assert.Empty(app.Services.GetServices<IHostedService>().OfType<WorkerLoop>());
        Assert.Null(app.Services.GetService<JobScheduler>());
        Assert.Null(app.Services.GetService<PAO.Infrastructure.Outbox.OutboxRelay>());
        await app.StopAsync();
        Assert.Equal(0, await running);
        await app.DisposeAsync();
    }
}
