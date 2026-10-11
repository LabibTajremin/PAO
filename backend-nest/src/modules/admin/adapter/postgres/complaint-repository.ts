import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database, type SqlClient } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import {
  type Comment,
  type Complaint,
  type ComplaintStatus,
  type ReporterRole,
} from '../../domain/complaint';
import { AdminErrors } from '../../app/errors';
import {
  type ComplaintFilter,
  type ComplaintRepository,
  type NewComplaint,
} from '../../port/complaint-repository';
import { ADMIN_OUTBOX, type AdminOutbox } from './outbox';
import {
  complaintByID,
  type ComplaintByIDRow,
  complaintsInvolving,
  countComplaintsAgainst,
  countVerifiedComplaints,
  insertComment,
  insertComplaint,
  listComments,
  listComplaints,
  lockComplaint,
  updateComplaint,
} from './sqlc/queries_sql';

function toComplaint(r: ComplaintByIDRow, comments: Comment[] = []): Complaint {
  return {
    ...r,
    ticket: Number(r.ticketNumber),
    reporterRole: r.reporterRole as ReporterRole,
    status: r.status as ComplaintStatus,
    photos: r.photoMediaIds,
    comments,
  };
}

/** The complaints tables of the admin schema. */
@Injectable()
export class PostgresComplaintRepository implements ComplaintRepository {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(ADMIN_OUTBOX) private readonly outbox: AdminOutbox,
  ) {}

  createComplaint(c: NewComplaint, event: (stored: Complaint) => DomainEvent): Promise<Complaint> {
    return this.db.transaction(async (tx) => {
      const row = await insertComplaint(tx, { ...c, photoMediaIds: [...c.photos] });
      const stored = { ...c, ticket: Number(row?.ticketNumber), comments: [] };
      await this.outbox.write(tx, c.id, event(stored));
      return stored;
    });
  }

  async getComplaint(id: string): Promise<Complaint> {
    const row = await complaintByID(this.db.pool, { id });
    if (row === null) {
      throw new DomainError(AdminErrors.ComplaintNotFound);
    }
    const comments = await listComments(this.db.pool, { complaintId: id });
    return toComplaint(row, comments);
  }

  async listComplaints(f: ComplaintFilter): Promise<Complaint[]> {
    const rows = await listComplaints(this.db.pool, {
      status: f.status,
      assigneeId: f.assigneeId,
      beforeAt: f.after?.createdAt ?? null,
      // The query ignores the id without a time; any uuid satisfies the parameter type.
      beforeId: f.after?.id ?? '00000000-0000-0000-0000-000000000000',
      maxRows: String(f.limit),
    });
    return rows.map((r) => toComplaint(r));
  }

  async saveComplaint(
    id: string,
    change: (c: Complaint) => { complaint: Complaint; event?: DomainEvent },
  ): Promise<Complaint> {
    await this.db.transaction(async (tx) => {
      const { complaint, event } = change(await this.lock(tx, id));
      await updateComplaint(tx, complaint);
      if (event !== undefined) {
        await this.outbox.write(tx, id, event);
      }
    });
    return this.getComplaint(id);
  }

  private async lock(tx: SqlClient, id: string): Promise<Complaint> {
    const row = await lockComplaint(tx, { id });
    if (row === null) {
      throw new DomainError(AdminErrors.ComplaintNotFound);
    }
    return toComplaint(row);
  }

  addComment(c: Comment): Promise<void> {
    return insertComment(this.db.pool, c);
  }

  async countVerifiedComplaints(againstId: string): Promise<number> {
    return Number((await countVerifiedComplaints(this.db.pool, { againstId }))?.count);
  }

  async countComplaintsAgainst(againstId: string): Promise<number> {
    return Number((await countComplaintsAgainst(this.db.pool, { againstId }))?.count);
  }

  async complaintsInvolving(id: string, limit: number): Promise<Complaint[]> {
    const rows = await complaintsInvolving(this.db.pool, { reporterId: id, limit: String(limit) });
    return rows.map((r) => toComplaint(r));
  }
}
