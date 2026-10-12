/** Why the audit log refused an entry. */
export const AuditReasons = {
  /** An entry needs an action and a subject. */
  Invalid: 'audit.entry_invalid',
} as const;

/**
 * Who did what to which subject, when and why. Entries are never changed after they are
 * written (PRD §6.4).
 */
export interface Entry {
  readonly id: string;
  readonly at: Date;
  /** Null for system actions such as scheduled jobs. */
  readonly actorId: string | null;
  readonly actorRole: string;
  readonly action: string;
  readonly subjectType: string;
  readonly subjectId: string;
  readonly reason: string;
  readonly before: Readonly<Record<string, unknown>> | null;
  readonly after: Readonly<Record<string, unknown>> | null;
  /** The event the entry was written from; it keeps redelivered events from repeating. */
  readonly eventId: string | null;
}

/** Narrows the audit log (A-08); absent fields do not filter. */
export interface Filter {
  readonly actorId?: string;
  readonly action?: string;
  readonly subjectType?: string;
  readonly subjectId?: string;
  readonly from?: Date;
  readonly to?: Date;
}

/** Reports whether the entry names an action and a subject. */
export function isComplete(e: Pick<Entry, 'action' | 'subjectType' | 'subjectId'>): boolean {
  return [e.action, e.subjectType, e.subjectId].every((s) => s.trim() !== '');
}
