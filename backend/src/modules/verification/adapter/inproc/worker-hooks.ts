import { Injectable } from '@nestjs/common';
import { type EventBus } from '../../../../platform/events/event-bus';
import { Payload } from '../../../../platform/events/payload';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { IdentityEvents } from '../../../identity/contract/events';
import { ProviderEvents } from '../../../provider/contract/events';
import { ExpireDocuments } from '../../app/expiry';
import { ProfileChanges } from '../../app/profile-changes';
import { DocumentRetention } from '../../app/retention';

/**
 * Re-reviews changed profile steps, blocks suspended or banned providers, starts the
 * retention clock of deleted accounts, and runs the daily expiry, reminder and
 * retention purge jobs (Asia/Dhaka). Both handlers converge on the same state
 * when an event is delivered twice.
 */
@Injectable()
@WorkerHooksProvider()
export class VerificationWorker implements WorkerHooks {
  constructor(
    private readonly changes: ProfileChanges,
    private readonly expiry: ExpireDocuments,
    private readonly retention: DocumentRetention,
  ) {}

  subscribe(bus: EventBus): void {
    bus.subscribe(ProviderEvents.EnrolmentStepSaved, 'verification', (env) => {
      const p = new Payload(env);
      return this.changes.onStepSaved(p.id('providerId'), p.text('step'));
    });
    bus.subscribe(IdentityEvents.AccountStatusChanged, 'verification', (env) => {
      const p = new Payload(env);
      return this.changes.onAccountStatus(p.id('accountId'), p.text('to'));
    });
    bus.subscribe(IdentityEvents.AccountDeleted, 'verification', (env) =>
      this.retention.closed(new Payload(env).id('accountId')),
    );
  }

  schedule(jobs: JobScheduler): void {
    jobs.dailyAt(2, 0, 'verification.expire_documents', () => this.expiry.expireDocuments());
    jobs.dailyAt(9, 0, 'verification.expiry_reminders', () => this.expiry.remindExpiring());
    jobs.dailyAt(3, 45, 'verification.purge_closed', async () => {
      await this.retention.purgeExpired();
    });
  }
}
