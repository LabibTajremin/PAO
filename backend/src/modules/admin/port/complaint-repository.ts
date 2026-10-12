import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Comment, type Complaint, type ComplaintStatus } from '../domain/complaint';

/** Selects a page of the complaints queue, newest first. */
export interface ComplaintFilter {
  readonly status: ComplaintStatus | null;
  readonly assigneeId: string | null;
  /** The last row of the previous page; null for the first page. */
  readonly after: { readonly createdAt: Date; readonly id: string } | null;
  readonly limit: number;
}

/** A complaint before it is stored; the database assigns the ticket number. */
export type NewComplaint = Omit<Complaint, 'ticket' | 'comments'>;

/** Stores complaints and their comments. */
export interface ComplaintRepository {
  /**
   * Stores the complaint with the next ticket number and writes the event built from
   * the stored complaint in the same transaction.
   */
  createComplaint(c: NewComplaint, event: (stored: Complaint) => DomainEvent): Promise<Complaint>;
  /** Returns a complaint with its comments, or throws `admin.complaint_not_found`. */
  getComplaint(id: string): Promise<Complaint>;
  listComplaints(filter: ComplaintFilter): Promise<Complaint[]>;
  /**
   * Applies `change` to the locked row and writes the event it returns, if any; returns
   * the saved complaint with its comments.
   */
  saveComplaint(
    id: string,
    change: (c: Complaint) => { complaint: Complaint; event?: DomainEvent },
  ): Promise<Complaint>;
  addComment(comment: Comment): Promise<void>;
  countVerifiedComplaints(againstId: string): Promise<number>;
  countComplaintsAgainst(id: string): Promise<number>;
  /** Lists the newest complaints a person reported or received. */
  complaintsInvolving(id: string, limit: number): Promise<Complaint[]>;
}

/** Injection token for the {@link ComplaintRepository}. */
export const COMPLAINT_REPOSITORY = Symbol('ComplaintRepository');
