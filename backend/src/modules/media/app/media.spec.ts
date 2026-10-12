import { v4 as uuidv4 } from 'uuid';
import { MediaReason } from '../domain/media';
import { UPLOAD_URL_TTL_MS } from './create-upload';
import { fakeMedia, uploaded } from './fake-media';
import { ORPHAN_AFTER_MS } from './media-objects';
import { VIEW_URL_TTL_MS } from './view-media';

const boom = new Error('boom');
const reason = (r: string) => ({ reason: r });

describe('media use cases', () => {
  it('uploads, confirms and views a document with an audit entry', async () => {
    const m = fakeMedia();
    const owner = uuidv4();
    const viewer = { id: uuidv4(), role: 'verifier' };
    const ticket = await uploaded(m, owner, 'nid_front');
    expect(ticket.url).not.toBe('');
    expect(ticket.expiresAt.getTime()).toBe(m.clock.now().getTime() + UPLOAD_URL_TTL_MS);
    await expect(m.views.viewUrl(ticket.mediaId, viewer)).rejects.toMatchObject(
      reason(MediaReason.NotFound),
    );
    expect((await m.confirmations.confirm(owner, ticket.mediaId)).confirmed).toBe(true);
    expect((await m.confirmations.confirm(owner, ticket.mediaId)).confirmed).toBe(true);
    const view = await m.views.viewUrl(ticket.mediaId, viewer);
    expect(view.url).not.toBe('');
    expect(view.expiresAt.getTime()).toBe(m.clock.now().getTime() + VIEW_URL_TTL_MS);
    expect(await m.audit.listForSubject()).toHaveLength(1);
    expect(m.audit.entries[0]).toMatchObject({
      actorId: viewer.id,
      actorRole: 'verifier',
      action: 'media.document_viewed',
      subjectType: 'media',
      subjectId: ticket.mediaId,
      after: { purpose: 'nid_front', owner },
    });
    const avatar = await uploaded(m, owner, 'avatar');
    await m.confirmations.confirm(owner, avatar.mediaId);
    await m.views.viewUrl(avatar.mediaId, { id: viewer.id, role: 'customer' });
    expect(m.audit.entries).toHaveLength(1);
    expect((await m.objects.get(avatar.mediaId)).purpose).toBe('avatar');
  });

  it('refuses confirmations that do not match', async () => {
    const m = fakeMedia();
    const owner = uuidv4();
    await expect(
      m.uploads.create(owner, 'customer', {
        purpose: 'nid_front',
        contentType: 'image/jpeg',
        sizeBytes: 1,
      }),
    ).rejects.toMatchObject(reason(MediaReason.Forbidden));
    const ticket = await uploaded(m, owner, 'selfie');
    await expect(m.confirmations.confirm(uuidv4(), ticket.mediaId)).rejects.toMatchObject(
      reason(MediaReason.NotFound),
    );
    const key = m.repo.objects.get(ticket.mediaId)?.key ?? '';
    m.store.files.set(key, { size: 999, contentType: 'image/jpeg' });
    await expect(m.confirmations.confirm(owner, ticket.mediaId)).rejects.toMatchObject(
      reason(MediaReason.NotUploaded),
    );
    expect(m.store.files.size).toBe(0);
    await expect(m.confirmations.confirm(owner, ticket.mediaId)).rejects.toMatchObject(
      reason(MediaReason.NotUploaded),
    );
    m.store.files.set(key, { size: 1000, contentType: 'image/png' });
    m.store.faults.set('delete', boom);
    await expect(m.confirmations.confirm(owner, ticket.mediaId)).rejects.toMatchObject({
      reason: MediaReason.NotUploaded,
      cause: boom,
    });
    m.store.faults.set('head', boom);
    await expect(m.confirmations.confirm(owner, ticket.mediaId)).rejects.toBe(boom);
  });

  it('reports failing records and signing', async () => {
    const file = { purpose: 'selfie', contentType: 'image/jpeg', sizeBytes: 1 };
    const m = fakeMedia();
    m.repo.faults.set('create', boom);
    await expect(m.uploads.create(uuidv4(), 'provider', file)).rejects.toBe(boom);
    m.repo.faults.clear();
    m.store.faults.set('presignPut', boom);
    await expect(m.uploads.create(uuidv4(), 'provider', file)).rejects.toBe(boom);
  });

  it('blocks a view whose audit fails, and unknown files', async () => {
    const m = fakeMedia();
    const owner = uuidv4();
    const ticket = await uploaded(m, owner, 'selfie');
    await m.confirmations.confirm(owner, ticket.mediaId);
    m.audit.failure = boom;
    await expect(m.views.viewUrl(ticket.mediaId, { id: owner, role: 'v' })).rejects.toMatchObject({
      message: 'audit document view',
      cause: boom,
    });
    await expect(m.views.viewUrl(uuidv4(), { id: owner, role: 'v' })).rejects.toMatchObject(
      reason(MediaReason.NotFound),
    );
    await expect(m.objects.delete(uuidv4())).rejects.toMatchObject(reason(MediaReason.NotFound));
    m.store.faults.set('delete', boom);
    await expect(m.objects.delete(ticket.mediaId)).rejects.toBe(boom);
  });

  it('purges uploads never attached within a day', async () => {
    const m = fakeMedia();
    const owner = uuidv4();
    const kept = await uploaded(m, owner, 'selfie');
    await m.objects.markAttached(kept.mediaId);
    await uploaded(m, owner, 'selfie');
    m.clock.advance(ORPHAN_AFTER_MS + 60_000);
    expect(await m.objects.purgeOrphans()).toBe(1);
    expect(m.repo.objects.size).toBe(1);
    await uploaded(m, owner, 'selfie');
    m.clock.advance(ORPHAN_AFTER_MS + 60_000);
    m.store.faults.set('delete', boom);
    await expect(m.objects.purgeOrphans()).rejects.toBe(boom);
    m.repo.faults.set('orphans', boom);
    await expect(m.objects.purgeOrphans()).rejects.toBe(boom);
  });
});
