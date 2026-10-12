import { NIL as NIL_UUID, validate as isUuid } from 'uuid';
import { VALIDATION_FAILED } from './api-error';

/** Page sizes (04-decisions.md E7). */
export const DEFAULT_PAGE_SIZE = 20;
/** The largest page a client may ask for. */
export const MAX_PAGE_SIZE = 100;

/**
 * The last row of a page, ordered by (created_at, id) descending. `createdAt` keeps the
 * timestamp as text so Postgres' microseconds survive the round trip.
 */
export interface Cursor {
  readonly createdAt: string;
  readonly id: string;
}

const INVALID_CURSOR = VALIDATION_FAILED.withDetails({ field: 'cursor' });

/** Returns the opaque cursor string for `c`. */
export function encodeCursor(c: { createdAt: Date | string; id: string }): string {
  const t = c.createdAt instanceof Date ? c.createdAt.toISOString() : c.createdAt;
  return Buffer.from(JSON.stringify({ t, i: c.id })).toString('base64url');
}

/** Parses a cursor; none or empty means the first page, a malformed one is a 422. */
export function decodeCursor(s: string | undefined): Cursor | undefined {
  if (s === undefined || s === '') {
    return undefined;
  }
  if (!/^[A-Za-z0-9_-]+$/.test(s)) {
    throw INVALID_CURSOR;
  }
  let raw: unknown;
  try {
    raw = JSON.parse(Buffer.from(s, 'base64url').toString());
  } catch {
    throw INVALID_CURSOR;
  }
  const { t, i } = (raw ?? {}) as { t?: unknown; i?: unknown };
  if (!isTimestamp(t) || !isRowId(i)) {
    throw INVALID_CURSOR;
  }
  return { createdAt: t, id: i };
}

const isTimestamp = (t: unknown): t is string =>
  typeof t === 'string' && !Number.isNaN(Date.parse(t));

const isRowId = (i: unknown): i is string => typeof i === 'string' && isUuid(i) && i !== NIL_UUID;

/** Returns the requested page size clamped to [1, {@link MAX_PAGE_SIZE}]. */
export function pageSize(limit: number | undefined): number {
  if (limit === undefined || limit < 1) {
    return DEFAULT_PAGE_SIZE;
  }
  return Math.min(limit, MAX_PAGE_SIZE);
}
