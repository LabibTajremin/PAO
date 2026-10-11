// Cleanups registered by kit helpers run after each spec file (see jest-setup.ts), in
// reverse order, like Go's t.Cleanup.
const cleanups: (() => Promise<unknown>)[] = [];

/** Registers `fn` to run when the current spec file finishes. */
export function onCleanup(fn: () => Promise<unknown>): void {
  cleanups.push(fn);
}

/** Runs and forgets every registered cleanup; errors are ignored. */
export async function runCleanups(): Promise<void> {
  while (cleanups.length > 0) {
    const fn = cleanups.pop();
    await fn?.().catch(() => undefined);
  }
}

/** Returns a PAO_TEST_* variable, defaulting to the local docker-compose services. */
export function testEnv(name: string): string {
  const defaults: Record<string, string> = {
    PAO_TEST_DATABASE_URL: 'postgres://pao:pao@localhost:5432/pao?sslmode=disable',
    PAO_TEST_REDIS_URL: 'redis://localhost:6379/15',
    PAO_TEST_S3_ENDPOINT: 'http://localhost:9000',
    PAO_TEST_S3_ACCESS_KEY: 'pao-local',
    PAO_TEST_S3_SECRET_KEY: 'change-me-local-only',
  };
  const value = process.env[name] ?? defaults[name];
  if (value === undefined || value === '') {
    throw new Error(`${name} is not set`);
  }
  return value;
}
