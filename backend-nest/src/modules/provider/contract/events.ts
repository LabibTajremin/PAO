import { type DomainEvent } from '../../../platform/events/domain-event';
import { type EnrolmentStep } from './enrolment';

/** Outbox names of the provider module's events; stored, so they never change. */
export const ProviderEvents = {
  EnrolmentStepSaved: 'provider.EnrolmentStepSaved',
  ProviderFlaggedForReview: 'provider.ProviderFlaggedForReview',
  ProviderWentOffline: 'provider.ProviderWentOffline',
} as const;

/**
 * Published when a provider saves a non-document step, so the matching verification
 * item returns to review.
 */
export interface EnrolmentStepSaved extends DomainEvent<typeof ProviderEvents.EnrolmentStepSaved> {
  readonly providerId: string;
  readonly step: EnrolmentStep;
}

/** Published when quality thresholds are crossed (D13). */
export interface ProviderFlaggedForReview extends DomainEvent<
  typeof ProviderEvents.ProviderFlaggedForReview
> {
  readonly providerId: string;
  readonly reason: string;
}

/**
 * Published when a provider leaves presence, including a forced offline after
 * heartbeat loss, a ban or an expired document.
 */
export interface ProviderWentOffline extends DomainEvent<
  typeof ProviderEvents.ProviderWentOffline
> {
  readonly providerId: string;
  readonly reason: string;
}

/** Any event the provider module publishes. */
export type ProviderEvent = EnrolmentStepSaved | ProviderFlaggedForReview | ProviderWentOffline;
