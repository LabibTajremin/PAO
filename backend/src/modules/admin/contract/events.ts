import { type DomainEvent } from '../../../platform/events/domain-event';

/** Outbox names of the admin module's events; stored, so they never change. */
export const AdminEvents = {
  ComplaintCreated: 'admin.ComplaintCreated',
  ComplaintResolved: 'admin.ComplaintResolved',
  SettingChanged: 'admin.SettingChanged',
} as const;

/** Published when either side reports a problem (C-14). */
export interface ComplaintCreated extends DomainEvent<typeof AdminEvents.ComplaintCreated> {
  readonly complaintId: string;
  readonly ticketNumber: string;
  readonly bookingId: string;
  readonly reporterId: string;
  readonly reporterRole: string;
  readonly againstId: string;
}

/** Published when support resolves a complaint (A-07). */
export interface ComplaintResolved extends DomainEvent<typeof AdminEvents.ComplaintResolved> {
  readonly complaintId: string;
  readonly ticketNumber: string;
  readonly bookingId: string;
  readonly reporterId: string;
  readonly reporterRole: string;
  readonly againstId: string;
  readonly verified: boolean;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}

/** Published when an admin edits a setting; the audit trail keeps both values. */
export interface SettingChanged extends DomainEvent<typeof AdminEvents.SettingChanged> {
  readonly key: string;
  readonly before: string;
  readonly after: string;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}

/** Any event the admin module publishes. */
export type AdminEvent = ComplaintCreated | ComplaintResolved | SettingChanged;
