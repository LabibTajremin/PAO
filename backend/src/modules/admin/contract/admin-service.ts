import { type Settings } from './dto';

/** What other modules may ask of the admin module (PRD §9.3 rule 1). */
export interface AdminService {
  /** Returns the typed platform settings (A-10), defaults filled in. */
  getSettings(): Promise<Settings>;
  /**
   * Returns verified complaints against a person; they feed the provider quality
   * review (PRD §6.4).
   */
  countVerifiedComplaints(againstId: string): Promise<number>;
}

/** Injection token for the {@link AdminService}. */
export const ADMIN_SERVICE = Symbol('AdminService');
