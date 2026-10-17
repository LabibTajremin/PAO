import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type AuditEntry } from '../../audit/contract/dto';
import { type BookingSummary } from '../../booking/contract/dto';
import { type Service } from '../../catalog/contract/dto';
import { type AccountStatus } from '../../identity/contract/dto';
import { type ProviderQuery, type ProviderRecord } from '../../provider/contract/admin-search';
import { type Provider } from '../../provider/contract/dto';
import { type Item } from '../../verification/contract/dto';
import { COMPLAINT_REPOSITORY, type ComplaintRepository } from '../port/complaint-repository';
import { CONSOLE, type Console } from '../port/console';
import { AdminErrors } from './errors';

/** Bounds the detail screens. */
export const HISTORY_SIZE = 50;
/** Bounds the detail screens. */
export const RECENT_SIZE = 10;

/** The admin provider record (A-05). */
export interface ProviderDetail {
  readonly record: ProviderRecord;
  readonly services: Service[];
  readonly profile: Provider;
  readonly items: Item[];
  readonly recent: BookingSummary[];
  readonly complaints: number;
  readonly cancellations30d: number;
  readonly history: AuditEntry[];
}

/** The admin provider screens, read from the modules that own the data (ADR-0026). */
@Injectable()
export class ProviderConsole {
  constructor(
    @Inject(CONSOLE) private readonly console: Console,
    @Inject(COMPLAINT_REPOSITORY) private readonly complaints: ComplaintRepository,
  ) {}

  /** Lists providers, newest first. */
  list(query: ProviderQuery): Promise<ProviderRecord[]> {
    return this.console.providers().searchProviders(query);
  }

  /** Names services for provider rows; a failed lookup only drops a name. */
  async services(ids: readonly string[]): Promise<Service[]> {
    const found = await Promise.all(
      ids.map((id) =>
        this.console
          .catalog()
          .getService(id)
          .catch(() => undefined),
      ),
    );
    return found.filter((s) => s !== undefined);
  }

  /** Gathers one provider's record, verification, bookings and history. */
  async detail(id: string): Promise<ProviderDetail> {
    const record = await this.record(id);
    const c = this.console;
    const services = await this.services(record.serviceIds);
    const profile = await c.providers().getProvider(id);
    const items = await c.verification().getItems(id);
    const recent = await c.bookings().listRecentBookings(id, RECENT_SIZE);
    const complaints = await this.complaints.countComplaintsAgainst(id);
    const stats = await c.bookings().getProviderStats(id);
    const history = await c.audit().listForSubject('account', id, HISTORY_SIZE);
    const { cancellations30d } = stats;
    return { record, services, profile, items, recent, complaints, cancellations30d, history };
  }

  /**
   * Suspends, bans or reinstates a provider (A-05). Identity revokes sessions and blocks
   * the phone; the status event takes them offline and blocks their NID (PRD §6.4).
   */
  async setStatus(change: StatusChange): Promise<ProviderDetail> {
    await this.record(change.accountId);
    await this.console.identity().setAccountStatus(change);
    const d = await this.detail(change.accountId);
    // The provider read model catches up from the event; show the decision at once.
    const pending = change.status === 'active' && d.record.level === 0;
    return { ...d, record: { ...d.record, status: pending ? 'pending' : change.status } };
  }

  private async record(id: string): Promise<ProviderRecord> {
    const [record] = await this.console.providers().searchProviders({
      id,
      text: '',
      status: '',
      level: null,
      flagged: null,
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

/** An admin's decision on an account. */
export interface StatusChange {
  readonly actorId: string;
  readonly accountId: string;
  readonly status: AccountStatus;
  readonly reason: string;
}
