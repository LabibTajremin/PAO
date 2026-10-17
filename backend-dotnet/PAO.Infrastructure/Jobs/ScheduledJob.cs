using PAO.Infrastructure.Data;

namespace PAO.Infrastructure.Jobs;

/// <summary>How a run ended; `Skipped` means another worker held the job's lock.</summary>
public enum JobOutcome
{
    /// <summary>Ok.</summary>
    Ok,
    /// <summary>Failed.</summary>
    Failed,
    /// <summary>Skipped.</summary>
    Skipped,
}

/// <summary>Told about every run, so failing jobs can alert (ops/prometheus).</summary>
public interface IJobObserver
{
    /// <summary>A run of `job` ended with `outcome` after `duration`.</summary>
    void JobFinished(string job, JobOutcome outcome, TimeSpan duration);
}

/// <summary>When a job runs: every interval, or daily at an Asia/Dhaka wall-clock time.</summary>
public abstract record JobSchedule
{
    /// <summary>How long to wait from `now` until the next run.</summary>
    public abstract TimeSpan DelayFrom(DateTimeOffset now);

    /// <summary>Runs every `interval`, the first time one interval after start.</summary>
    public static JobSchedule Every(TimeSpan interval) => new EverySchedule(interval);

    /// <summary>Runs once a day at `hour:minute` Asia/Dhaka (e.g. expiry at 02:00).</summary>
    public static JobSchedule DailyAt(int hour, int minute) => new DailySchedule(hour, minute);

    /// <summary>The next time after `now` that Asia/Dhaka wall clocks show `hour:minute`.</summary>
    public static DateTimeOffset NextDailyRun(DateTimeOffset now, int hour, int minute)
    {
        var local = now.ToOffset(DhakaTime.Offset);
        var run = new DateTimeOffset(local.Year, local.Month, local.Day, hour, minute, 0, DhakaTime.Offset);
        return run > now ? run : run.AddDays(1);
    }

    private sealed record EverySchedule(TimeSpan Interval) : JobSchedule
    {
        public override TimeSpan DelayFrom(DateTimeOffset now) => Interval;
    }

    private sealed record DailySchedule(int Hour, int Minute) : JobSchedule
    {
        public override TimeSpan DelayFrom(DateTimeOffset now) => NextDailyRun(now, Hour, Minute) - now;
    }
}

/// <summary>
/// A periodic job an area registers for the worker (02-architecture §9). It must be
/// idempotent, as sweeps are; the scheduler runs it under a Postgres advisory lock named
/// after it, so with several workers exactly one runs it at a time.
/// </summary>
public interface IScheduledJob
{
    /// <summary>The stable job name, e.g. `booking.expire_requests`.</summary>
    string Name { get; }

    /// <summary>When it runs.</summary>
    JobSchedule Schedule { get; }

    /// <summary>Does one run.</summary>
    Task Run(CancellationToken cancellationToken);
}
