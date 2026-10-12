/**
 * Runs `task` again and again, waiting `delayMs()` before each run, until stopped. A run
 * never overlaps the previous one; `stop` waits for a run in progress. `task` handles its
 * own errors.
 */
export class Ticker {
  private timer?: NodeJS.Timeout;
  private running: Promise<void> = Promise.resolve();
  private active = false;

  constructor(
    private readonly delayMs: () => number,
    private readonly task: () => Promise<void>,
  ) {}

  /** Schedules the first run. */
  start(): void {
    this.active = true;
    this.schedule();
  }

  /** Cancels the next run and waits for the current one. */
  async stop(): Promise<void> {
    this.active = false;
    clearTimeout(this.timer);
    await this.running;
  }

  private schedule(): void {
    this.timer = setTimeout(() => {
      this.running = this.task().then(() => {
        if (this.active) {
          this.schedule();
        }
      });
    }, this.delayMs());
  }
}
