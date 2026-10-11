import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { AdminEvents, type ComplaintResolved } from '../contract/events';
import {
  assign,
  type Complaint,
  ComplaintStatus,
  isValidResolution,
  resolve,
  ticketNumber,
} from '../domain/complaint';
import {
  COMPLAINT_REPOSITORY,
  type ComplaintFilter,
  type ComplaintRepository,
} from '../port/complaint-repository';
import { ADMINS, type Admins } from '../port/peers';
import { STAMPS, type Stamps } from '../port/stamps';
import { AdminErrors } from './errors';

function assertUnresolved(c: Complaint): void {
  if (c.status === ComplaintStatus.Resolved) {
    throw new DomainError(AdminErrors.AlreadyResolved);
  }
}

/** The support queue: read, assign, comment and resolve complaints (A-07). */
@Injectable()
export class WorkComplaints {
  constructor(
    @Inject(COMPLAINT_REPOSITORY) private readonly repo: ComplaintRepository,
    @Inject(ADMINS) private readonly admins: Admins,
    @Inject(STAMPS) private readonly stamps: Stamps,
  ) {}

  /** Returns one complaint with its comments. */
  get(id: string): Promise<Complaint> {
    return this.repo.getComplaint(id);
  }

  /** Returns a page of the queue, newest first. */
  list(filter: ComplaintFilter): Promise<Complaint[]> {
    return this.repo.listComplaints(filter);
  }

  /** Hands a complaint to an admin who may work the queue. */
  async assign(id: string, assigneeId: string): Promise<Complaint> {
    if (!(await this.admins.canWorkComplaints(assigneeId))) {
      throw new DomainError(AdminErrors.AssigneeInvalid);
    }
    return this.repo.saveComplaint(id, (c) => {
      assertUnresolved(c);
      return { complaint: assign(c, assigneeId, this.stamps.clock.now()) };
    });
  }

  /** Adds an internal note and returns the complaint with every note. */
  async comment(id: string, authorId: string, body: string): Promise<Complaint> {
    await this.repo.getComplaint(id);
    await this.repo.addComment({
      id: this.stamps.ids.newId(),
      complaintId: id,
      authorId,
      body,
      at: this.stamps.clock.now(),
    });
    return this.repo.getComplaint(id);
  }

  /**
   * Closes a complaint. ComplaintResolved tells the reporter and, when verified, feeds
   * the provider quality review (PRD §6.4).
   */
  resolve(id: string, actorId: string, note: string, verified: boolean): Promise<Complaint> {
    return this.repo.saveComplaint(id, (c) => {
      assertUnresolved(c);
      if (!isValidResolution(note)) {
        throw new DomainError(AdminErrors.ComplaintInvalid);
      }
      const complaint = resolve(c, note, verified, this.stamps.clock.now());
      return { complaint, event: resolved(complaint, actorId) };
    });
  }
}

function resolved(c: Complaint, actorId: string): ComplaintResolved {
  return {
    name: AdminEvents.ComplaintResolved,
    complaintId: c.id,
    ticketNumber: ticketNumber(c),
    bookingId: c.bookingId,
    reporterId: c.reporterId,
    reporterRole: c.reporterRole,
    againstId: c.againstId,
    verified: c.verified,
    actorId,
  };
}
