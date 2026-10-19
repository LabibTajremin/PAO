using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Data.Migrations;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Jobs;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Outbox;

namespace PAO.BackgroundJobs;

/// <summary>Deletes delivered outbox events after the retention period (daily 03:00).</summary>
public sealed class OutboxPurgeJob(OutboxMaintenance maintenance, IClock clock, IOptions<JobsOptions> options) : IScheduledJob
{
    /// <inheritdoc />
    public string Name => "outbox.purge_published";

    /// <inheritdoc />
    public JobSchedule Schedule { get; } = JobSchedule.DailyAt(3, 0);

    /// <inheritdoc />
    public Task Run(CancellationToken cancellationToken) =>
        maintenance.PurgePublished(clock.Now - TimeSpan.FromDays(options.Value.OutboxRetentionDays), cancellationToken);
}

/// <summary>Runs the scheduler and the outbox relay for the lifetime of the worker.</summary>
public sealed class WorkerLoop(JobScheduler scheduler, OutboxRelay relay, IOptions<JobsOptions> options, ILogger<WorkerLoop> logger) : BackgroundService
{
    /// <inheritdoc />
    protected override Task ExecuteAsync(CancellationToken stoppingToken) =>
        Task.WhenAll(scheduler.RunAll(stoppingToken), Relay(stoppingToken));

    /// <summary>Relays until stopped; a failed pass is logged and the next one retries.</summary>
    public async Task Relay(CancellationToken stoppingToken)
    {
        var interval = TimeSpan.FromMilliseconds(options.Value.OutboxRelayIntervalMs);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await relay.RunOnce(stoppingToken);
                await Task.Delay(interval, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception error) when (error is NpgsqlException or InvalidOperationException)
            {
                logger.LogError(error, "outbox relay pass failed");
                await Task.Delay(interval, CancellationToken.None);
            }
        }
    }
}

/// <summary>Registers what the worker runs: the bus with every area's subscribers, the relay and the jobs.</summary>
public static class WorkerServices
{
    /// <summary>Adds the scheduler, the relay over the outbox modules listed in "DB Changes/modules.json" and the platform jobs.</summary>
    public static IServiceCollection AddBackgroundJobs(this IServiceCollection services, PaoPaths paths)
    {
        var outboxModules = new MigrationFiles(paths.Migrations).ReadModuleLists().OutboxModules;
        services.AddSingleton(sp =>
        {
            var bus = new EventBus();
            foreach (var subscriptions in sp.GetServices<IEventSubscriptions>())
            {
                subscriptions.Subscribe(bus);
            }
            return bus;
        });
        services.AddSingleton(sp => sp.GetRequiredService<PaoMetrics>().Worker);
        services.AddSingleton(sp => new OutboxMaintenance(sp.GetRequiredService<NpgsqlDataSource>(), outboxModules));
        services.AddSingleton(sp => new OutboxRelay(
            sp.GetRequiredService<NpgsqlDataSource>(), sp.GetRequiredService<EventBus>(), outboxModules,
            sp.GetRequiredService<IClock>(), sp.GetRequiredService<WorkerMetrics>(), sp.GetRequiredService<ILogger<OutboxRelay>>()));
        services.AddSingleton<IScheduledJob, OutboxPurgeJob>();
        services.AddSingleton<IScheduledJob, MediaOrphanPurgeJob>();
        services.AddSingleton<IScheduledJob, MerchantPresenceReapJob>();
        services.AddSingleton<IScheduledJob, ExpireDocumentsJob>();
        services.AddSingleton<IScheduledJob, ExpiryRemindersJob>();
        services.AddSingleton<IScheduledJob, PurgeClosedAccountsJob>();
        services.AddSingleton(sp => new JobScheduler(
            sp.GetRequiredService<NpgsqlDataSource>(), sp.GetServices<IScheduledJob>(), sp.GetRequiredService<IClock>(),
            sp.GetRequiredService<WorkerMetrics>(), sp.GetRequiredService<ILogger<JobScheduler>>()));
        services.AddHostedService<WorkerLoop>();
        return services;
    }
}
