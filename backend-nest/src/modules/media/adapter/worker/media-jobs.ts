import { Inject, Injectable } from '@nestjs/common';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { type WorkerHooks, WorkerHooksProvider } from '../../../../platform/worker/worker-hooks';
import { MediaObjects } from '../../app/media-objects';

/** The daily orphan purge (`media.purge_orphans`, 02-architecture §9). */
@Injectable()
@WorkerHooksProvider()
export class MediaJobs implements WorkerHooks {
  constructor(@Inject(MediaObjects) private readonly objects: MediaObjects) {}

  schedule(jobs: JobScheduler): void {
    jobs.dailyAt(3, 30, 'media.purge_orphans', async () => {
      await this.objects.purgeOrphans();
    });
  }
}
