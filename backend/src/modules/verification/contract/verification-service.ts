import { type Item } from './dto';

/** What other modules may ask of verification (PRD §9.3 rule 1). */
export interface VerificationService {
  /** Returns the provider's verification level (0 when never verified). */
  getLevel(providerId: string): Promise<number>;
  /** Returns levels for many providers at once, keyed by provider id, for search ranking. */
  getLevels(providerIds: readonly string[]): Promise<Map<string, number>>;
  /**
   * Reports whether the provider may receive bookings for the service: Level ≥ the
   * service's required level (Level 2 when flagged), no expired document and not
   * blocked (PRD §6.1, §6.4). A null `serviceId` checks any service.
   */
  canReceiveBookings(providerId: string, serviceId: string | null): Promise<boolean>;
  /** Returns the provider's verification items sorted by type (A-05). */
  getItems(providerId: string): Promise<Item[]>;
  /** Counts submitted providers with an item awaiting review (A-09). */
  countPendingReviews(): Promise<number>;
}

/** Injection token for the {@link VerificationService}. */
export const VERIFICATION_SERVICE = Symbol('VerificationService');
