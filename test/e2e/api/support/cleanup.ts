type Cleanup = () => Promise<unknown>;

const pending: Cleanup[] = [];

/** Runs `fn` when the current test ends, pass or fail, after later-registered ones. */
export function onCleanup(fn: Cleanup): void {
  pending.push(fn);
}

/** Runs and forgets the registered cleanups, newest first, as Go's t.Cleanup does. */
export async function runCleanups(): Promise<void> {
  const errors: unknown[] = [];
  for (let fn = pending.pop(); fn !== undefined; fn = pending.pop()) {
    try {
      await fn();
    } catch (err) {
      errors.push(err);
    }
  }
  if (errors.length > 0) throw new AggregateError(errors, 'cleanup failed');
}
