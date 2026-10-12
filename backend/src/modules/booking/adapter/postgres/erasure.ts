import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type EventBus } from '../../../../platform/events/event-bus';
import { Payload } from '../../../../platform/events/payload';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { IdentityEvents } from '../../../identity/contract/events';
import { eraseCustomerSnapshots, eraseProviderSnapshots } from './sqlc/queries_sql';

/**
 * Blanks a deleted account's personal details in the booking snapshots (PRD §11).
 * The updates are idempotent, so a redelivered event is harmless.
 */
@Injectable()
@WorkerHooksProvider()
export class BookingErasure implements WorkerHooks {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  subscribe(bus: EventBus): void {
    bus.subscribe(IdentityEvents.AccountDeleted, 'booking', (env) =>
      this.erase(new Payload(env).id('accountId')),
    );
  }

  /** The account may have booked, served, or both. */
  erase(accountId: string): Promise<void> {
    return this.db.transaction(async (tx) => {
      await eraseCustomerSnapshots(tx, { customerId: accountId });
      await eraseProviderSnapshots(tx, { providerId: accountId });
    });
  }
}
