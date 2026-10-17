import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { REDIS } from './redis-client';

/** What is stored under an idempotency key: the request fingerprint and, once done, the answer. */
export interface IdempotencyRecord {
  readonly requestHash: string;
  readonly done: boolean;
  readonly status?: number;
  readonly body?: Buffer;
}

/** The stored JSON, field for field what the Go backend wrote (`b` is base64). */
interface StoredRecord {
  h: string;
  d: boolean;
  s?: number;
  b?: string;
}

/** Idempotency records live 24 h, so retries within a day get the first answer (PRD §9.6). */
export const IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000;

function encode(rec: IdempotencyRecord): string {
  const stored: StoredRecord = { h: rec.requestHash, d: rec.done };
  if (rec.status) {
    stored.s = rec.status;
  }
  if (rec.body && rec.body.length > 0) {
    stored.b = rec.body.toString('base64');
  }
  return JSON.stringify(stored);
}

function decode(key: string, raw: string): IdempotencyRecord {
  try {
    const s = JSON.parse(raw) as StoredRecord;
    return {
      requestHash: s.h,
      done: s.d,
      status: s.s,
      body: s.b === undefined ? undefined : Buffer.from(s.b, 'base64'),
    };
  } catch (cause) {
    throw new Error(`decode ${key}`, { cause });
  }
}

/** The result of {@link IdempotencyStore.reserve}. */
export interface Reservation {
  /** True when this request claimed the key; false when `record` was already there. */
  readonly reserved: boolean;
  readonly record: IdempotencyRecord;
}

/** Remembers responses per idempotency key. */
@Injectable()
export class IdempotencyStore {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  /** Claims `key` for a new request, or returns what is stored; one atomic SET NX GET. */
  async reserve(key: string, requestHash: string): Promise<Reservation> {
    const pending: IdempotencyRecord = { requestHash, done: false };
    let previous: string | null;
    try {
      previous = await this.redis.set(key, encode(pending), 'PX', IDEMPOTENCY_TTL_MS, 'NX', 'GET');
    } catch (cause) {
      throw new Error(`reserve ${key}`, { cause });
    }
    if (previous === null) {
      return { reserved: true, record: pending };
    }
    return { reserved: false, record: decode(key, previous) };
  }

  /** Stores the answer of the reserved request. */
  async complete(key: string, rec: Omit<IdempotencyRecord, 'done'>): Promise<void> {
    try {
      await this.redis.set(key, encode({ ...rec, done: true }), 'PX', IDEMPOTENCY_TTL_MS);
    } catch (cause) {
      throw new Error(`complete ${key}`, { cause });
    }
  }

  /** Forgets a reservation whose request failed, so the client may retry. */
  async release(key: string): Promise<void> {
    try {
      await this.redis.del(key);
    } catch (cause) {
      throw new Error(`release ${key}`, { cause });
    }
  }
}
