/** Records who did what to which subject, when and why. */
export interface AuditEntry {
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
}
