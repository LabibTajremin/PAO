import { type AuditEntry } from './dto';

/** What other modules may ask of the audit module (PRD §9.3 rule 1). */
export interface AuditService {
  /** Appends an entry. Entries can never be edited or deleted (PRD §6.4). */
  record(entry: AuditEntry): Promise<void>;
  /**
   * Returns the newest entries about one subject, e.g. a provider's status history on
   * the admin detail page.
   */
  listForSubject(subjectType: string, subjectId: string, limit: number): Promise<AuditEntry[]>;
}

/** Injection token for the {@link AuditService}. */
export const AUDIT_SERVICE = Symbol('AuditService');
