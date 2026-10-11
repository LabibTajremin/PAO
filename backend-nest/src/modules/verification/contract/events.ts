import { type DomainEvent } from '../../../platform/events/domain-event';
import { type ItemType } from './dto';

/** Outbox names of verification's events; stored, so they never change. */
export const VerificationEvents = {
  ProviderLevelChanged: 'verification.ProviderLevelChanged',
  DocumentApproved: 'verification.DocumentApproved',
  DocumentRejected: 'verification.DocumentRejected',
  DocumentExpired: 'verification.DocumentExpired',
  DocumentExpiring: 'verification.DocumentExpiring',
  Level2SessionScheduled: 'verification.Level2SessionScheduled',
  Level2ResultRecorded: 'verification.Level2ResultRecorded',
} as const;

/** Published whenever a provider's level goes up or down. */
export interface ProviderLevelChanged extends DomainEvent<
  typeof VerificationEvents.ProviderLevelChanged
> {
  readonly providerId: string;
  readonly from: number;
  readonly to: number;
  readonly reason: string;
}

/** Published when a verifier approves an item. */
export interface DocumentApproved extends DomainEvent<typeof VerificationEvents.DocumentApproved> {
  readonly providerId: string;
  readonly item: ItemType;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}

/** Published when a verifier rejects an item with a reason. */
export interface DocumentRejected extends DomainEvent<typeof VerificationEvents.DocumentRejected> {
  readonly providerId: string;
  readonly item: ItemType;
  readonly reason: string;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}

/** Published by the daily expiry job (PRD §6.4). */
export interface DocumentExpired extends DomainEvent<typeof VerificationEvents.DocumentExpired> {
  readonly providerId: string;
  readonly item: ItemType;
}

/** Reminds a provider 30, 7 and 1 days before expiry (P-11). */
export interface DocumentExpiring extends DomainEvent<typeof VerificationEvents.DocumentExpiring> {
  readonly providerId: string;
  readonly item: ItemType;
  readonly daysLeft: number;
}

/** Tells the provider when and where to attend. */
export interface Level2SessionScheduled extends DomainEvent<
  typeof VerificationEvents.Level2SessionScheduled
> {
  readonly providerId: string;
  readonly sessionId: string;
  /** ISO-8601 time of the session. */
  readonly scheduledAt: string;
  readonly location: string;
}

/**
 * Published when a verifier records a Level 2 result, so the decision is audited
 * (PRD §6.4).
 */
export interface Level2ResultRecorded extends DomainEvent<
  typeof VerificationEvents.Level2ResultRecorded
> {
  readonly providerId: string;
  readonly sessionId: string;
  readonly result: string;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}

/** Any event verification publishes. */
export type VerificationEvent =
  | ProviderLevelChanged
  | DocumentApproved
  | DocumentRejected
  | DocumentExpired
  | DocumentExpiring
  | Level2SessionScheduled
  | Level2ResultRecorded;
