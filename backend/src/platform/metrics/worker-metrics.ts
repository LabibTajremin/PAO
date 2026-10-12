import { Counter, Gauge, Histogram, type Registry } from 'prom-client';
import { type JobObserver, type JobOutcome } from '../jobs/scheduler';
import { type OutboxBacklog } from '../outbox/outbox';
import { type RelayObserver } from '../outbox/outbox-relay';

/**
 * The worker's metrics: job runs, outbox deliveries and backlog. Delivered booking
 * events double as the booking funnel, since each one is counted once, when its outbox
 * row is marked published.
 */
export class WorkerMetrics implements JobObserver, RelayObserver {
  private readonly jobRuns: Counter<'job' | 'outcome'>;
  private readonly jobDuration: Histogram<'job'>;
  private readonly delivered: Counter<'module' | 'event'>;
  private readonly failed: Counter<'module' | 'event' | 'dead'>;
  private backlog: () => Promise<readonly OutboxBacklog[]> = () => Promise.resolve([]);
  private reading?: Promise<readonly OutboxBacklog[]>;

  constructor(registry: Registry) {
    const registers = [registry];
    this.jobRuns = new Counter({
      name: 'pao_job_runs_total',
      help: 'Scheduled job runs by outcome (ok, failed, skipped while another worker held the lock).',
      labelNames: ['job', 'outcome'],
      registers,
    });
    this.jobDuration = new Histogram({
      name: 'pao_job_duration_seconds',
      help: 'Duration of scheduled job runs that held the lock.',
      labelNames: ['job'],
      buckets: [0.05, 0.25, 1, 5, 15, 60, 300],
      registers,
    });
    this.delivered = new Counter({
      name: 'pao_outbox_events_delivered_total',
      help: 'Outbox events delivered to every subscriber, by module and event name.',
      labelNames: ['module', 'event'],
      registers,
    });
    this.failed = new Counter({
      name: 'pao_outbox_delivery_failures_total',
      help: 'Failed outbox deliveries; dead="true" when the event was dead-lettered.',
      labelNames: ['module', 'event', 'dead'],
      registers,
    });
    this.backlogGauges(registers);
  }

  /** Reads the outbox backlog at every scrape from `source`. */
  trackBacklog(source: () => Promise<readonly OutboxBacklog[]>): void {
    this.backlog = source;
  }

  jobFinished(job: string, outcome: JobOutcome, seconds: number): void {
    this.jobRuns.inc({ job, outcome });
    if (outcome !== 'skipped') {
      this.jobDuration.observe({ job }, seconds);
    }
  }

  eventDelivered(module: string, event: string): void {
    this.delivered.inc({ module, event });
  }

  eventFailed(module: string, event: string, dead: boolean): void {
    this.failed.inc({ module, event, dead: String(dead) });
  }

  private backlogGauges(registers: Registry[]): void {
    // The three gauges are collected together, so one query serves a whole scrape.
    const read = () =>
      (this.reading ??= this.backlog().finally(() => {
        this.reading = undefined;
      }));
    new Gauge({
      name: 'pao_outbox_pending_events',
      help: 'Outbox events waiting for delivery, by module.',
      labelNames: ['module'],
      registers,
      async collect() {
        this.reset();
        for (const b of await read()) this.set({ module: b.module }, b.pending);
      },
    });
    new Gauge({
      name: 'pao_outbox_oldest_pending_seconds',
      help: 'Age of the oldest undelivered outbox event, by module (0 when none wait).',
      labelNames: ['module'],
      registers,
      async collect() {
        this.reset();
        for (const b of await read()) this.set({ module: b.module }, b.oldestSeconds);
      },
    });
    new Gauge({
      name: 'pao_outbox_dead_events',
      help: 'Dead-lettered outbox events kept for inspection, by module.',
      labelNames: ['module'],
      registers,
      async collect() {
        this.reset();
        for (const b of await read()) this.set({ module: b.module }, b.dead);
      },
    });
  }
}
