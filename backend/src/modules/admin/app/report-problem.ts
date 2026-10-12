import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { AdminEvents, type ComplaintCreated } from '../contract/events';
import {
  type Complaint,
  type ComplaintReport,
  ComplaintStatus,
  isValidReport,
  ticketNumber,
} from '../domain/complaint';
import { COMPLAINT_REPOSITORY, type ComplaintRepository } from '../port/complaint-repository';
import { BOOKINGS, type Bookings, EVIDENCE_PHOTOS, type EvidencePhotos } from '../port/peers';
import { STAMPS, type Stamps } from '../port/stamps';
import { AdminErrors } from './errors';

/** Files a complaint by one party of a booking against the other (C-14). */
@Injectable()
export class ReportProblem {
  constructor(
    @Inject(COMPLAINT_REPOSITORY) private readonly repo: ComplaintRepository,
    @Inject(BOOKINGS) private readonly bookings: Bookings,
    @Inject(EVIDENCE_PHOTOS) private readonly photos: EvidencePhotos,
    @Inject(STAMPS) private readonly stamps: Stamps,
  ) {}

  /**
   * Stores the report against the other party. A stranger to the booking gets
   * `admin.booking_not_found`, so booking ids cannot be probed.
   */
  async execute(r: ComplaintReport): Promise<Complaint> {
    if (!isValidReport(r)) {
      throw new DomainError(AdminErrors.ComplaintInvalid);
    }
    const { customerId, providerId } = await this.bookings.parties(r.bookingId);
    const [me, other] =
      r.reporterRole === 'customer' ? [customerId, providerId] : [providerId, customerId];
    if (me !== r.reporterId) {
      throw new DomainError(AdminErrors.BookingNotFound);
    }
    await this.photos.attach(r.reporterId, r.photos);
    const now = this.stamps.clock.now();
    const complaint = {
      ...r,
      id: this.stamps.ids.newId(),
      againstId: other,
      status: ComplaintStatus.Open,
      assigneeId: null,
      resolution: '',
      verified: false,
      createdAt: now,
      updatedAt: now,
      resolvedAt: null,
    };
    return this.repo.createComplaint(complaint, created);
  }
}

function created(c: Complaint): ComplaintCreated {
  return {
    name: AdminEvents.ComplaintCreated,
    complaintId: c.id,
    ticketNumber: ticketNumber(c),
    bookingId: c.bookingId,
    reporterId: c.reporterId,
    reporterRole: c.reporterRole,
    againstId: c.againstId,
  };
}
