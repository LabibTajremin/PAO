import { Injectable } from '@nestjs/common';
import { type EventBus } from '../../../../platform/events/event-bus';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { ManagePresence } from '../../app/presence';
import { ReadModelHandlers } from '../postgres/read-model';

/** The provider module's read-model handlers and presence reaper. */
@Injectable()
@WorkerHooksProvider()
export class ProviderWorker implements WorkerHooks {
  constructor(
    private readonly handlers: ReadModelHandlers,
    private readonly presence: ManagePresence,
  ) {}

  subscribe(bus: EventBus): void {
    this.handlers.subscribe(bus);
  }

  schedule(jobs: JobScheduler): void {
    jobs.every(60_000, 'provider.reap_lost_presence', () => this.presence.reapLost());
  }
}
