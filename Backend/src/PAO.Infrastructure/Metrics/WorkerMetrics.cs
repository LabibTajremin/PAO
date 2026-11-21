using PAO.Infrastructure.Jobs;
using PAO.Infrastructure.Outbox;
using Prometheus;

namespace PAO.Infrastructure.Metrics;

/// <summary>
/// The worker's metrics: job runs, outbox deliveries and backlog. Delivered booking events
/// double as the booking funnel, since each one is counted once, when its outbox row is
/// marked published.
/// </summary>
public sealed class WorkerMetrics : IJobObserver, IRelayObserver
{
    // Job names are labelled "name": Prometheus reserves "job" for the scrape target.
    private readonly Counter jobRuns;
    private readonly Histogram jobDuration;
    private readonly Counter delivered;
    private readonly Counter failed;
    private readonly Gauge pending;
    private readonly Gauge oldest;
    private readonly Gauge dead;
    private Func<CancellationToken, Task<IReadOnlyList<OutboxBacklog>>> backlog = _ => Task.FromResult<IReadOnlyList<OutboxBacklog>>([]);

    /// <summary>Registers the worker metrics in `registry`.</summary>
    public WorkerMetrics(CollectorRegistry registry, MetricFactory factory)
    {
        jobRuns = factory.CreateCounter("pao_job_runs_total", "Scheduled job runs by outcome (ok, failed, skipped while another worker held the lock).", "name", "outcome");
        jobDuration = factory.CreateHistogram("pao_job_duration_seconds", "Duration of scheduled job runs that held the lock.", new HistogramConfiguration
        {
            LabelNames = ["name"],
            Buckets = [0.05, 0.25, 1, 5, 15, 60, 300],
        });
        delivered = factory.CreateCounter("pao_outbox_events_delivered_total", "Outbox events delivered to every subscriber, by module and event name.", "module", "event");
        failed = factory.CreateCounter("pao_outbox_delivery_failures_total", "Failed outbox deliveries; dead=\"true\" when the event was dead-lettered.", "module", "event", "dead");
        pending = factory.CreateGauge("pao_outbox_pending_events", "Outbox events waiting for delivery, by module.", "module");
        oldest = factory.CreateGauge("pao_outbox_oldest_pending_seconds", "Age of the oldest undelivered outbox event, by module (0 when none wait).", "module");
        dead = factory.CreateGauge("pao_outbox_dead_events", "Dead-lettered outbox events kept for inspection, by module.", "module");
        // The three gauges are read together, so one query serves a whole scrape.
        registry.AddBeforeCollectCallback(async cancellationToken =>
        {
            foreach (var b in await backlog(cancellationToken))
            {
                pending.WithLabels(b.Module).Set(b.Pending);
                oldest.WithLabels(b.Module).Set(b.OldestSeconds);
                dead.WithLabels(b.Module).Set(b.Dead);
            }
        });
    }

    /// <summary>Reads the outbox backlog at every scrape from `source`.</summary>
    public void TrackBacklog(Func<CancellationToken, Task<IReadOnlyList<OutboxBacklog>>> source) => backlog = source;

    /// <inheritdoc />
    public void JobFinished(string job, JobOutcome outcome, TimeSpan duration)
    {
        jobRuns.WithLabels(job, outcome.ToString().ToLowerInvariant()).Inc();
        if (outcome != JobOutcome.Skipped)
        {
            jobDuration.WithLabels(job).Observe(duration.TotalSeconds);
        }
    }

    /// <inheritdoc />
    public void EventDelivered(string module, string eventName) => delivered.WithLabels(module, eventName).Inc();

    /// <inheritdoc />
    public void EventFailed(string module, string eventName, bool isDead) =>
        failed.WithLabels(module, eventName, isDead ? "true" : "false").Inc();
}
