import { type Clock, DHAKA_OFFSET_MS } from '../clock/clock';
import { type CheckedOutClient, type Database } from '../db/database';
import { type Logger } from '../logging/logger';
import { Ticker } from './ticker';

/** A periodic job; it must be idempotent, as sweeps are. */
export type Job = () => Promise<void>;

/** How a run ended; `skipped` means another worker held the job's lock. */
export type JobOutcome = 'ok' | 'failed' | 'skipped';

/** Told about every run, so failing jobs can alert (ops/prometheus). */
export interface JobObserver {
  jobFinished(job: string, outcome: JobOutcome, seconds: number): void;
}

const ignoreRuns: JobObserver = { jobFinished: () => undefined };

// The advisory-lock namespace of scheduled jobs; the second key is hashtext(job name).
const JOB_LOCK_CLASS = 7041;
const DAY_MS = 24 * 60 * 60 * 1000;

/** The next time after `now` that Asia/Dhaka wall clocks show `hour:minute`. */
export function nextDailyRun(now: Date, hour: number, minute: number): Date {
  const local = new Date(now.getTime() + DHAKA_OFFSET_MS);
  const runLocal = Date.UTC(
    local.getUTCFullYear(),
    local.getUTCMonth(),
    local.getUTCDate(),
    hour,
    minute,
  );
  const next = runLocal - DHAKA_OFFSET_MS;
  return new Date(next > now.getTime() ? next : next + DAY_MS);
}

/**
 * Runs the worker's periodic jobs (ADR-0032). Each run holds a Postgres advisory lock on
 * the job's name, so with several workers only one runs a job at a time.
 */
export class JobScheduler {
  private readonly jobs = new Map<string, { job: Job; ticker: Ticker }>();

  constructor(
    private readonly db: Database,
    private readonly clock: Clock,
    private readonly log: Logger,
    private readonly observer: JobObserver = ignoreRuns,
  ) {}

  /** Runs `job` every `intervalMs`, the first time one interval after start. */
  every(intervalMs: number, name: string, job: Job): void {
    this.add(name, job, () => intervalMs);
  }

  /** Runs `job` once a day at `hour:minute` Asia/Dhaka (e.g. expiry at 02:00). */
  dailyAt(hour: number, minute: number, name: string, job: Job): void {
    this.add(name, job, () => {
      const now = this.clock.now();
      return nextDailyRun(now, hour, minute).getTime() - now.getTime();
    });
  }

  /** Starts every job's timer. */
  start(): void {
    for (const { ticker } of this.jobs.values()) {
      ticker.start();
    }
  }

  /** Stops the timers and waits for runs in progress. */
  async stop(): Promise<void> {
    await Promise.all([...this.jobs.values()].map(({ ticker }) => ticker.stop()));
  }

  /**
   * Runs the job now under its lock; false when another worker holds it. Failures are
   * logged, never thrown, so one broken job cannot stop the others.
   */
  async runNow(name: string): Promise<boolean> {
    const entry = this.jobs.get(name);
    if (!entry) {
      throw new Error(`unknown job ${name}`);
    }
    const client = await this.db.checkout();
    const started = performance.now();
    let locked = false;
    let outcome: JobOutcome = 'skipped';
    try {
      const { rows } = await client.query<{ locked: boolean }>(
        'SELECT pg_try_advisory_lock($1, hashtext($2)) AS locked',
        [JOB_LOCK_CLASS, name],
      );
      locked = rows[0]?.locked === true;
      if (locked) {
        outcome = 'failed';
        await entry.job();
        outcome = 'ok';
      }
    } catch (err) {
      outcome = 'failed';
      this.log.error({ err, job: name }, 'job failed');
    } finally {
      await this.unlock(client, name, locked);
    }
    this.observer.jobFinished(name, outcome, (performance.now() - started) / 1000);
    return locked;
  }

  private async unlock(client: CheckedOutClient, name: string, locked: boolean): Promise<void> {
    if (!locked) {
      client.done();
      return;
    }
    const unlocked = await client
      .query('SELECT pg_advisory_unlock($1, hashtext($2))', [JOB_LOCK_CLASS, name])
      .then(
        () => true,
        () => false,
      );
    client.done(!unlocked);
  }

  private add(name: string, job: Job, delayMs: () => number): void {
    if (this.jobs.has(name)) {
      throw new Error(`job ${name} is scheduled twice`);
    }
    const ticker = new Ticker(delayMs, async () => {
      await this.runNow(name).catch((err: unknown) => {
        this.log.error({ err, job: name }, 'job could not start');
      });
    });
    this.jobs.set(name, { job, ticker });
  }
}
