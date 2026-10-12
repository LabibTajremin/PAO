import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type AuditEntry } from '../../audit/contract/dto';
import { type BookingSummary } from '../../booking/contract/dto';
import { type CustomerQuery, type CustomerRecord } from '../../customer/contract/admin-search';
import { type RatingSummary } from '../../rating/contract/dto';
import { type Complaint } from '../domain/complaint';
import { COMPLAINT_REPOSITORY, type ComplaintRepository } from '../port/complaint-repository';
import { CONSOLE, type Console } from '../port/console';
import { AdminErrors } from './errors';
import { HISTORY_SIZE, RECENT_SIZE, type StatusChange } from './provider-console';

/** The admin customer record (A-05). */
export interface CustomerDetail {
  readonly record: CustomerRecord;
  readonly rating: RatingSummary;
  readonly recent: BookingSummary[];
  readonly complaints: Complaint[];
  readonly history: AuditEntry[];
}

/** The admin customer screens, read from the modules that own the data (ADR-0026). */
@Injectable()
export class CustomerConsole {
  constructor(
    @Inject(CONSOLE) private readonly console: Console,
    @Inject(COMPLAINT_REPOSITORY) private readonly complaints: ComplaintRepository,
  ) {}

  /** Lists customers, newest first. */
  list(query: CustomerQuery): Promise<CustomerRecord[]> {
    return this.console.customers().searchCustomers(query);
  }

  /** Gathers one customer's record, rating, bookings, complaints and history. */
  async detail(id: string): Promise<CustomerDetail> {
    const record = await this.record(id);
    const c = this.console;
    const rating = await c.ratings().getCustomerRating(id);
    const recent = await c.bookings().listRecentBookings(id, RECENT_SIZE);
    const complaints = await this.complaints.complaintsInvolving(id, RECENT_SIZE);
    const history = await c.audit().listForSubject('account', id, HISTORY_SIZE);
    return { record, rating, recent, complaints, history };
  }

  /** Suspends, bans or reinstates a customer (A-05). */
  async setStatus(change: StatusChange): Promise<CustomerDetail> {
    await this.record(change.accountId);
    await this.console.identity().setAccountStatus(change);
    const d = await this.detail(change.accountId);
    return { ...d, record: { ...d.record, status: change.status } };
  }

  private async record(id: string): Promise<CustomerRecord> {
    const [record] = await this.console.customers().searchCustomers({
      id,
      text: '',
      status: '',
      afterAt: null,
      afterId: null,
      limit: 1,
    });
    if (record === undefined) {
      throw new DomainError(AdminErrors.PersonNotFound);
    }
    return record;
  }
}
