import { type DomainEvent } from '../../../platform/events/domain-event';
import { type ProviderQuery, type ProviderRecord } from '../contract/admin-search';
import { type Candidate } from '../domain/nearby';
import { type Provider } from '../domain/provider';

/** A search row with the provider's own working radius. */
export interface RadiusCandidate extends Candidate {
  readonly workingRadiusM: number;
}

/** Stores provider profiles. */
export interface ProviderRepository {
  /** Creates an empty profile on first use. */
  ensure(id: string, phone: string, at: Date): Promise<void>;
  /** Returns the profile, or throws `provider.not_found`. */
  get(id: string): Promise<Provider>;
  /**
   * Writes the profile fields and services (never the read-model copies) and the events
   * in one transaction.
   */
  save(p: Provider, events?: readonly DomainEvent[]): Promise<void>;
  /** Writes events without changing the profile. */
  publish(id: string, events: readonly DomainEvent[]): Promise<void>;
  /** Loads active providers at or above `minLevel` among `ids`; distances are 0. */
  candidates(ids: readonly string[], minLevel: number): Promise<RadiusCandidate[]>;
  /** Lists providers for the admin console; `online` is left for presence. */
  search(q: ProviderQuery): Promise<ProviderRecord[]>;
}

/** Injection token for the {@link ProviderRepository}. */
export const PROVIDER_REPOSITORY = Symbol('ProviderRepository');
