import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database, type SqlClient } from '../../../../platform/db/database';
import { isDomainError } from '../../../../platform/errors/domain-error';
import { type Envelope, type EventBus } from '../../../../platform/events/event-bus';
import { Payload } from '../../../../platform/events/payload';
import { idempotentHandler } from '../../../../platform/outbox/outbox';
import { AdminEvents } from '../../../admin/contract/events';
import { BookingEvents } from '../../../booking/contract/events';
import { IdentityEvents } from '../../../identity/contract/events';
import { RatingEvents } from '../../../rating/contract/events';
import { VerificationEvents } from '../../../verification/contract/events';
import { ManagePresence } from '../../app/presence';
import { type ProviderFlaggedForReview, ProviderEvents } from '../../contract/events';
import { ProviderReasons } from '../../domain/reasons';
import { SETTINGS, type Settings } from '../../port/peers';
import { PROVIDER_OUTBOX, type ProviderOutbox } from './outbox';
import {
  addCancellation,
  addCompletedJob,
  countCancellations,
  deleteProvider,
  flagQuery,
  setAccountStatus,
  setLevel,
  setRating,
} from './sqlc/queries_sql';

type Apply = (tx: SqlClient, p: Payload, env: Envelope) => Promise<void>;

const CANCELLATION_WINDOW_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Keeps the read-model copies (level, status, rating, jobs) current and flags providers
 * for review when quality thresholds are crossed (PRD §6.4, D13).
 */
@Injectable()
export class ReadModelHandlers {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(PROVIDER_OUTBOX) private readonly outbox: ProviderOutbox,
    @Inject(SETTINGS) private readonly settings: Settings,
    private readonly presence: ManagePresence,
  ) {}

  /** Registers every handler, each applied once per event. */
  subscribe(bus: EventBus): void {
    const handlers: Readonly<Record<string, Apply>> = {
      [VerificationEvents.ProviderLevelChanged]: (tx, p) => this.onLevel(tx, p),
      [IdentityEvents.AccountStatusChanged]: (tx, p) => this.onStatus(tx, p),
      [IdentityEvents.AccountDeleted]: (tx, p) => this.onDeleted(tx, p),
      [RatingEvents.ReviewSubmitted]: (tx, p) => this.onReview(tx, p),
      [BookingEvents.BookingCompleted]: (tx, p) => addCompletedJob(tx, { id: p.id('providerId') }),
      [BookingEvents.BookingCancelled]: (tx, p, env) => this.onCancelled(tx, p, env.occurredAt),
      [AdminEvents.ComplaintResolved]: (tx, p) => this.onComplaint(tx, p),
    };
    for (const [name, apply] of Object.entries(handlers)) {
      const handle = (tx: SqlClient, env: Envelope) => apply(tx, new Payload(env), env);
      bus.subscribe(name, 'provider', idempotentHandler(this.db, 'provider', name, handle));
    }
  }

  /** Events also arrive for accounts that never enrolled as providers. */
  private async offline(id: string, reason: string): Promise<void> {
    try {
      await this.presence.goOffline(id, reason);
    } catch (err) {
      if (!isDomainError(err, ProviderReasons.NotFound)) {
        throw err;
      }
    }
  }

  private async onLevel(tx: SqlClient, p: Payload): Promise<void> {
    const id = p.id('providerId');
    const level = p.number('to');
    await setLevel(tx, { id, level });
    if (level < 1) {
      await this.offline(id, 'level_dropped');
    }
  }

  private async onStatus(tx: SqlClient, p: Payload): Promise<void> {
    const id = p.id('accountId');
    const status = p.text('to');
    await setAccountStatus(tx, { id, accountStatus: status });
    if (status !== 'active') {
      await this.offline(id, `account_${status}`);
    }
  }

  private async onDeleted(tx: SqlClient, p: Payload): Promise<void> {
    const id = p.id('accountId');
    await this.offline(id, 'account_deleted');
    await deleteProvider(tx, { id });
  }

  private async flag(tx: SqlClient, id: string, reason: string): Promise<void> {
    const res = await tx.query(flagQuery, [id, reason]);
    if (res.rowCount === 1) {
      const event: ProviderFlaggedForReview = {
        name: ProviderEvents.ProviderFlaggedForReview,
        providerId: id,
        reason,
      };
      await this.outbox.write(tx, id, event);
    }
  }

  private async onReview(tx: SqlClient, p: Payload): Promise<void> {
    const id = p.id('subjectId');
    if (p.text('subjectRole') !== 'provider') {
      return;
    }
    const average = p.number('newAverage');
    const count = p.number('newCount');
    await setRating(tx, { id, ratingAvg: average, ratingCount: count });
    const t = await this.settings.quality();
    if (count >= t.ratingMinJobs && average < t.ratingFloor) {
      await this.flag(tx, id, 'rating_below_floor');
    }
  }

  private async onCancelled(tx: SqlClient, p: Payload, at: Date): Promise<void> {
    const providerId = p.id('providerId');
    const byProvider = p.text('by') === 'provider';
    if (!byProvider || !p.flag('afterAcceptance')) {
      return;
    }
    const bookingId = p.id('bookingId');
    await addCancellation(tx, { bookingId, providerId, at });
    const since = new Date(at.getTime() - CANCELLATION_WINDOW_MS);
    const n = Number((await countCancellations(tx, { providerId, at: since }))?.count);
    if (n > (await this.settings.quality()).maxCancellations) {
      await this.flag(tx, providerId, 'cancellations');
    }
  }

  private async onComplaint(tx: SqlClient, p: Payload): Promise<void> {
    const against = p.id('againstId');
    if (p.flag('verified')) {
      await this.flag(tx, against, 'verified_complaint');
    }
  }
}
