import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Session } from '../domain/level2';
import { type State } from '../domain/state';

/** Edits a provider's state in place and returns the events to publish with it. */
export type Change = (s: State) => DomainEvent[] | Promise<DomainEvent[]>;

/** A keyset position over (time, id); `limit` includes the look-ahead row. */
export interface Page {
  readonly at: Date | null;
  readonly id: string | null;
  readonly limit: number;
}

/** Narrows the review queue (A-03). */
export interface QueueFilter {
  readonly itemType: string | null;
  readonly serviceId: string | null;
}

/** A submitted provider with items waiting for a decision. */
export interface QueueRow {
  readonly providerId: string;
  readonly submittedAt: Date;
  readonly pendingItems: readonly string[];
  readonly serviceIds: readonly string[];
}

/** Narrows the Level 2 session list. */
export interface SessionFilter {
  readonly providerId: string | null;
  readonly status: string | null;
}

/** An approved item with an expiry date. */
export interface ExpiringItem {
  readonly providerId: string;
  readonly itemType: string;
  readonly expiresAt: Date;
}

/**
 * Stores verification state. `change` runs under the provider's row lock, so concurrent
 * decisions cannot compute the level from stale items.
 */
export interface VerificationRepository {
  load(id: string): Promise<State>;
  change(id: string, fn: Change): Promise<State>;
  levels(ids: readonly string[]): Promise<Map<string, number>>;
  countPendingReviews(): Promise<number>;
  queue(f: QueueFilter, p: Page): Promise<QueueRow[]>;
  sessions(f: SessionFilter, p: Page): Promise<Session[]>;
  /** Returns one session, or throws `verification.provider_not_found`. */
  session(id: string): Promise<Session>;
  /** Providers with approved items whose expiry is at or before `t`. */
  expiredBy(t: Date): Promise<string[]>;
  /** Approved items expiring in (from, to]. */
  expiringBetween(from: Date, to: Date): Promise<ExpiringItem[]>;
  /** Records a reminder with its event and reports whether it was new. */
  remindOnce(it: ExpiringItem, daysBefore: number, e: DomainEvent): Promise<boolean>;
  nidBlocked(hash: string): Promise<boolean>;
  /** Adds the provider's NID hash to the block list (PRD §6.4). */
  blockNid(id: string, reason: string): Promise<void>;
}

/** Injection token for the {@link VerificationRepository}. */
export const VERIFICATION_REPOSITORY = Symbol('VerificationRepository');
