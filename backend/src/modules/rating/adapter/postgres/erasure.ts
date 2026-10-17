import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type EventBus } from '../../../../platform/events/event-bus';
import { Payload } from '../../../../platform/events/payload';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { IdentityEvents } from '../../../identity/contract/events';
import { eraseAuthor, eraseReviewableNames } from './sqlc/queries_sql';

/**
 * Drops a deleted account's name and review comments (PRD §11); the stars stay so the
 * other side's average does not change. Idempotent under redelivery.
 */
@Injectable()
@WorkerHooksProvider()
export class RatingErasure implements WorkerHooks {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  subscribe(bus: EventBus): void {
    bus.subscribe(IdentityEvents.AccountDeleted, 'rating', (env) =>
      this.erase(new Payload(env).id('accountId')),
    );
  }

  erase(accountId: string): Promise<void> {
    return this.db.transaction(async (tx) => {
      await eraseAuthor(tx, { authorId: accountId });
      await eraseReviewableNames(tx, { customerId: accountId });
    });
  }
}
