/** Complaint statuses (A-07). */
export const ComplaintStatus = {
  Open: 'open',
  Assigned: 'assigned',
  Resolved: 'resolved',
} as const;

/** Where a complaint is in the support queue. */
export type ComplaintStatus = (typeof ComplaintStatus)[keyof typeof ComplaintStatus];

/** Which party of the booking reported. */
export type ReporterRole = 'customer' | 'provider';

/** Bounds the evidence a reporter attaches (C-14). */
export const MAX_COMPLAINT_PHOTOS = 5;

/** Reasons a booking can be reported for. */
export const COMPLAINT_REASONS: readonly string[] = [
  'no_show',
  'late',
  'poor_quality',
  'overcharge',
  'damage',
  'behaviour',
  'safety',
  'customer_unavailable',
  'payment',
  'other',
];

/** An internal support note on a complaint. */
export interface Comment {
  readonly id: string;
  readonly complaintId: string;
  readonly authorId: string;
  readonly body: string;
  readonly at: Date;
}

/** A problem reported on a booking by either side. */
export interface Complaint {
  readonly id: string;
  readonly ticket: number;
  readonly bookingId: string;
  readonly reporterId: string;
  readonly reporterRole: ReporterRole;
  readonly againstId: string;
  readonly reason: string;
  readonly description: string;
  readonly photos: readonly string[];
  readonly status: ComplaintStatus;
  readonly assigneeId: string | null;
  readonly resolution: string;
  readonly verified: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  readonly resolvedAt: Date | null;
  readonly comments: readonly Comment[];
}

/** What a reporter submits. */
export interface ComplaintReport {
  readonly bookingId: string;
  readonly reporterId: string;
  readonly reporterRole: ReporterRole;
  readonly reason: string;
  readonly description: string;
  readonly photos: readonly string[];
}

/** The reference shown to the reporter and support, e.g. TCK-001001. */
export function ticketNumber(c: Pick<Complaint, 'ticket'>): string {
  return `TCK-${String(c.ticket).padStart(6, '0')}`;
}

/** Counts characters the way Go's utf8.RuneCountInString does, after trimming. */
function trimmedLength(text: string): number {
  return Array.from(text.trim()).length;
}

/** Reports whether a new complaint's reason, description and photo list are acceptable. */
export function isValidReport(r: ComplaintReport): boolean {
  const n = trimmedLength(r.description);
  return (
    COMPLAINT_REASONS.includes(r.reason) &&
    n >= 10 &&
    n <= 1000 &&
    r.photos.length <= MAX_COMPLAINT_PHOTOS &&
    new Set(r.photos).size === r.photos.length
  );
}

/** Reports whether a resolution note has an acceptable length. */
export function isValidResolution(note: string): boolean {
  const n = trimmedLength(note);
  return n >= 5 && n <= 1000;
}

/** Hands a complaint to a support agent; reassigning is allowed until it is resolved. */
export function assign(c: Complaint, to: string, at: Date): Complaint {
  return { ...c, status: ComplaintStatus.Assigned, assigneeId: to, updatedAt: at };
}

/** Closes the complaint; a verified one counts against the other party (PRD §6.4). */
export function resolve(c: Complaint, note: string, verified: boolean, at: Date): Complaint {
  return {
    ...c,
    status: ComplaintStatus.Resolved,
    resolution: note,
    verified,
    updatedAt: at,
    resolvedAt: at,
  };
}
