using System.Diagnostics;
using Microsoft.Extensions.Logging;
using Npgsql;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Jobs;

namespace PAO.BackgroundJobs;

/// <summary>
/// Runs the worker's periodic jobs (02-architecture §9). Each run holds a Postgres advisory
/// lock on the job's name (class 7041, `hashtext(name)`, as NestJS), so with several
/// workers, of either backend, only one runs a job at a time.
/// </summary>
public sealed class JobScheduler
{
    private const int JobLockClass = 7041;
    private readonly NpgsqlDataSource dataSource;
    private readonly IClock clock;
    private readonly IJobObserver observer;
    private readonly ILogger<JobScheduler> logger;
    private readonly Func<TimeSpan, CancellationToken, Task> delay;

    /// <summary>Creates the scheduler; `delay` waits between runs (Task.Delay outside tests).</summary>
    public JobScheduler(
        NpgsqlDataSource dataSource, IEnumerable<IScheduledJob> jobs, IClock clock, IJobObserver observer,
        ILogger<JobScheduler> logger, Func<TimeSpan, CancellationToken, Task>? delay = null)
    {
        this.dataSource = dataSource;
        this.clock = clock;
        this.observer = observer;
        this.logger = logger;
        this.delay = delay ?? Task.Delay;
        Jobs = jobs.ToList();
        var twice = Jobs.GroupBy(j => j.Name).FirstOrDefault(g => g.Count() > 1);
        if (twice is not null)
        {
            throw new InvalidOperationException($"job {twice.Key} is scheduled twice");
        }
    }

    /// <summary>Every registered job.</summary>
    public IReadOnlyList<IScheduledJob> Jobs { get; }

    /// <summary>Runs every job on its schedule until `stoppingToken` fires.</summary>
    public Task RunAll(CancellationToken stoppingToken) => Task.WhenAll(Jobs.Select(j => RunForever(j, stoppingToken)));

    /// <summary>Waits for each scheduled time and runs `job`, until `stoppingToken` fires.</summary>
    public async Task RunForever(IScheduledJob job, CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await delay(job.Schedule.DelayFrom(clock.Now), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                return;
            }
            await RunNow(job, stoppingToken);
        }
    }

    /// <summary>
    /// Runs `job` now under its lock; false when another worker holds it. Failures are logged,
    /// never thrown, so one broken job cannot stop the others.
    /// </summary>
    public async Task<bool> RunNow(IScheduledJob job, CancellationToken cancellationToken)
    {
        var started = Stopwatch.GetTimestamp();
        var outcome = JobOutcome.Skipped;
        await using var connection = await dataSource.OpenConnectionAsync(cancellationToken);
        var locked = await Advisory(connection, "pg_try_advisory_lock", job.Name, cancellationToken);
        if (locked)
        {
            try
            {
                await job.Run(cancellationToken);
                outcome = JobOutcome.Ok;
            }
            catch (Exception error) when (error is not OperationCanceledException)
            {
                outcome = JobOutcome.Failed;
                logger.LogError(error, "job failed {Job}", job.Name);
            }
            finally
            {
                await Advisory(connection, "pg_advisory_unlock", job.Name, CancellationToken.None);
            }
        }
        observer.JobFinished(job.Name, outcome, Stopwatch.GetElapsedTime(started));
        return locked;
    }

    private static async Task<bool> Advisory(NpgsqlConnection connection, string function, string name, CancellationToken cancellationToken)
    {
        await using var command = new NpgsqlCommand($"SELECT {function}($1, hashtext($2))", connection);
        command.Parameters.Add(new NpgsqlParameter { Value = JobLockClass });
        command.Parameters.Add(new NpgsqlParameter { Value = name });
        return await command.ExecuteScalarAsync(cancellationToken) is true;
    }
}
