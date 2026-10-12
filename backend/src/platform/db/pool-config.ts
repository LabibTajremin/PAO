import { availableParallelism } from 'node:os';
import { type PoolConfig } from 'pg';

const DURATION_PART = /(\d+(?:\.\d+)?)(ms|s|m|h)/g;
const UNIT_MS: Readonly<Record<string, number>> = { ms: 1, s: 1000, m: 60_000, h: 3_600_000 };

/** Parses a Go duration such as `1h30m` or `90s` into milliseconds; undefined if invalid. */
export function parseGoDuration(text: string): number | undefined {
  if (!/^(?:\d+(?:\.\d+)?(?:ms|s|m|h))+$/.test(text)) {
    return undefined;
  }
  let total = 0;
  for (const [, amount, unit] of text.matchAll(DURATION_PART)) {
    total += Number(amount) * (UNIT_MS[unit ?? ''] ?? 0);
  }
  return total;
}

function positiveInt(text: string | null): number | undefined {
  const n = Number(text);
  return text !== null && Number.isInteger(n) && n > 0 ? n : undefined;
}

function durationParam(text: string | null): number | undefined {
  return text === null ? undefined : parseGoDuration(text);
}

/**
 * Builds the pool settings from a DATABASE_URL. Sizing follows pgxpool, which the Go
 * backend used: `pool_max_conns` (default max(4, CPUs)), `pool_max_conn_lifetime` (1h)
 * and `pool_max_conn_idle_time` (30m) in the URL, plus `connect_timeout` in seconds.
 */
export function poolConfig(databaseUrl: string): PoolConfig {
  const url = new URL(databaseUrl);
  // Percent-escapes are checked here because URL accepts them in non-http schemes.
  decodeURIComponent(url.host + url.pathname);
  const params = url.searchParams;
  const max = positiveInt(params.get('pool_max_conns')) ?? Math.max(4, availableParallelism());
  const lifetimeMs = durationParam(params.get('pool_max_conn_lifetime')) ?? 3_600_000;
  const idleMs = durationParam(params.get('pool_max_conn_idle_time')) ?? 1_800_000;
  const connectTimeout = positiveInt(params.get('connect_timeout'));
  for (const name of [...params.keys()].filter((k) => k.startsWith('pool_'))) {
    params.delete(name);
  }
  params.delete('connect_timeout');
  return {
    connectionString: url.toString(),
    max,
    maxLifetimeSeconds: Math.ceil(lifetimeMs / 1000),
    idleTimeoutMillis: idleMs,
    connectionTimeoutMillis: connectTimeout === undefined ? 0 : connectTimeout * 1000,
  };
}
