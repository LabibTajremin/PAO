import { type ProviderQuery, type ProviderRecord } from './admin-search';
import { type NearbyProvider, type NearbyQuery, type Provider } from './dto';
import { type EnrolmentStatus, type EnrolmentStep } from './enrolment';

/** What other modules may ask of the provider module (PRD §9.3 rule 1). */
export interface ProviderService {
  /** Returns a provider's profile, or throws `ProviderErrors.NotFound`. */
  getProvider(providerId: string): Promise<Provider>;
  /** Reports whether the provider is online right now. */
  isAvailable(providerId: string): Promise<boolean>;
  /**
   * Returns verified, online providers registered for the service within its radius:
   * Level 2 first, then by the requested sort (PRD §5, D11).
   */
  findNearby(query: NearbyQuery): Promise<NearbyProvider[]>;
  /**
   * Returns the wizard progress; a provider who has saved nothing yet has every step
   * open.
   */
  enrolment(providerId: string): Promise<EnrolmentStatus>;
  /** Records a document step saved by verification. */
  markStepDone(providerId: string, step: EnrolmentStep): Promise<EnrolmentStatus>;
  /** Records that the provider sent the enrolment for review. */
  markSubmitted(providerId: string): Promise<void>;
  /** Removes the provider from presence, e.g. after a ban or an expired document. */
  forceOffline(providerId: string): Promise<void>;
  /** Lists providers for the admin console, newest first (A-05). */
  searchProviders(query: ProviderQuery): Promise<ProviderRecord[]>;
}

/** Injection token for the {@link ProviderService}. */
export const PROVIDER_SERVICE = Symbol('ProviderService');
