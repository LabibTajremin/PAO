import { Inject, Injectable } from '@nestjs/common';
import { type EventBus } from '../../../../platform/events/event-bus';
import { Payload } from '../../../../platform/events/payload';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { type WorkerHooks, WorkerHooksProvider } from '../../../../platform/worker/worker-hooks';
import { IdentityEvents } from '../../../identity/contract/events';
import { MediaObjects } from '../../app/media-objects';

/** The daily orphan purge (`media.purge_orphans`, 02-architecture §9) and erasure. */
@Injectable()
@WorkerHooksProvider()
export class MediaJobs implements WorkerHooks {
  constructor(@Inject(MediaObjects) private readonly objects: MediaObjects) {}

  /** A deleted account's own files go at once; its documents wait for the purge. */
  subscribe(bus: EventBus): void {
    bus.subscribe(IdentityEvents.AccountDeleted, 'media', async (env) => {
      await this.objects.deleteOwned(new Payload(env).id('accountId'), false);
    });
  }

  schedule(jobs: JobScheduler): void {
    jobs.dailyAt(3, 30, 'media.purge_orphans', async () => {
      await this.objects.purgeOrphans();
    });
  }
}
