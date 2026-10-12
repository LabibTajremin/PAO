import { Injectable } from '@nestjs/common';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { bookingNumber } from '../../app/access';
import { ReadBookings } from '../../app/read-bookings';
import { RespondToRequests } from '../../app/respond';
import { type BookingService } from '../../contract/booking-service';
import {
  type Booking,
  type BookingStatus,
  type BookingSummary,
  type ProviderStats,
} from '../../contract/dto';

/** How often the request expiry sweep runs; a missed run catches up on the next. */
export const EXPIRE_EVERY_MS = 15_000;

/** The booking contract for other modules in the process. */
@Injectable()
export class BookingContract implements BookingService {
  constructor(private readonly reads: ReadBookings) {}

  async getBooking(bookingId: string): Promise<Booking> {
    const b = await this.reads.get(bookingId);
    return {
      id: b.id,
      number: bookingNumber(b.number),
      status: b.status,
      customerId: b.customer.id,
      providerId: b.provider.id,
      serviceId: b.serviceId,
      serviceName: b.serviceName,
      customerName: b.customer.name,
      providerName: b.provider.name,
      area: b.address.area,
      totalPaisa: b.totalPaisa,
      createdAt: b.createdAt,
      completedAt: b.completedAt,
    };
  }

  countActiveJobs(providerId: string): Promise<number> {
    return this.reads.countActive(providerId);
  }

  async getProviderStats(providerId: string): Promise<ProviderStats> {
    const s = await this.reads.stats(providerId);
    return { completedJobs: s.completed, cancellations30d: s.cancellations };
  }

  /** Either side's bookings: the customer's first, then the provider's. */
  async listRecentBookings(partyId: string, limit: number): Promise<BookingSummary[]> {
    const p = { at: null, id: null, limit };
    const rows = [
      ...(await this.reads.list(partyId, 'customer', 'all', p)),
      ...(await this.reads.list(partyId, 'provider', 'all', p)),
    ];
    return rows.map((r) => ({
      id: r.id,
      number: bookingNumber(r.number),
      status: r.status as BookingStatus,
      serviceName: r.serviceName,
      totalPaisa: r.totalPaisa,
      createdAt: r.createdAt,
    }));
  }
}

/** Runs `booking.expire_requests`: requests past their deadline time out (D12). */
@Injectable()
@WorkerHooksProvider()
export class BookingWorker implements WorkerHooks {
  constructor(private readonly responses: RespondToRequests) {}

  schedule(jobs: JobScheduler): void {
    jobs.every(EXPIRE_EVERY_MS, 'booking.expire_requests', () => this.responses.expireDue());
  }
}
