import { v4 as uuidv4 } from 'uuid';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { fakeMedia, uploaded } from '../../app/fake-media';
import { MediaErrors } from '../../contract/errors';
import { MediaJobs } from '../worker/media-jobs';
import { InprocMediaService } from './media-service';

function contractOf(m: ReturnType<typeof fakeMedia>): InprocMediaService {
  return new InprocMediaService(m.uploads, m.confirmations, m.views, m.objects);
}

describe('InprocMediaService', () => {
  it('serves uploads made by other modules', async () => {
    const m = fakeMedia();
    const c = contractOf(m);
    const owner = uuidv4();
    const req = { ownerId: owner, purpose: 'level2_photo', contentType: 'image/jpeg' } as const;
    const ticket = await c.createUploadUrl({ ...req, sizeBytes: 1000 });
    const key = m.repo.objects.get(ticket.mediaId)?.key ?? '';
    m.store.files.set(key, { size: 1000, contentType: 'image/jpeg' });
    expect(await c.confirmUpload(owner, ticket.mediaId)).toMatchObject({
      id: ticket.mediaId,
      ownerId: owner,
      purpose: 'level2_photo',
      confirmed: true,
    });
    await c.markAttached(ticket.mediaId);
    expect((await c.getObject(ticket.mediaId)).sizeBytes).toBe(1000);
    const view = await c.getViewUrl({ mediaId: ticket.mediaId, viewerId: owner, viewerRole: 'v' });
    expect(view.url).toContain(key);
    await c.delete(ticket.mediaId);
    await expect(c.getObject(ticket.mediaId)).rejects.toMatchObject({
      reason: MediaErrors.NotFound,
    });
  });

  it('answers with contract reasons', async () => {
    const m = fakeMedia();
    const c = contractOf(m);
    const avatar = { ownerId: uuidv4(), purpose: 'avatar', contentType: 'image/jpeg' } as const;
    await expect(c.createUploadUrl({ ...avatar, sizeBytes: 1 })).rejects.toMatchObject({
      reason: MediaErrors.UploadInvalid,
    });
    const photo = { ...avatar, purpose: 'level2_photo' } as const;
    await expect(c.createUploadUrl({ ...photo, sizeBytes: 0 })).rejects.toMatchObject({
      reason: MediaErrors.UploadInvalid,
    });
    const ticket = await c.createUploadUrl({ ...photo, sizeBytes: 10 });
    await expect(c.confirmUpload(photo.ownerId, ticket.mediaId)).rejects.toMatchObject({
      reason: MediaErrors.NotUploaded,
    });
  });
});

describe('MediaJobs', () => {
  it('purges orphans daily at 03:30', async () => {
    const m = fakeMedia();
    await uploaded(m, uuidv4(), 'selfie');
    m.clock.advance(25 * 60 * 60_000);
    const scheduled: { name: string; hour: number; minute: number; job: () => Promise<void> }[] =
      [];
    const jobs = {
      dailyAt: (hour: number, minute: number, name: string, job: () => Promise<void>) =>
        scheduled.push({ name, hour, minute, job }),
    } as unknown as JobScheduler;
    new MediaJobs(m.objects).schedule(jobs);
    expect(scheduled).toMatchObject([{ name: 'media.purge_orphans', hour: 3, minute: 30 }]);
    await scheduled[0]?.job();
    expect(m.repo.objects.size).toBe(0);
  });
});
