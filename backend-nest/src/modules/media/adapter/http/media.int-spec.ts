import { v4 as uuidv4 } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { putFile, upload } from '../../../../../test/kit/media';
import { adminSession, signIn } from '../../../../../test/kit/identity';
import { standIn } from '../../../../../test/kit/stand-in';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { discardLogger } from '../../../../platform/logging/logger';
import { JobScheduler } from '../../../../platform/jobs/scheduler';
import { type AuditEntry, AUDIT_SERVICE } from '../../../audit/contract';
import { MEDIA_SERVICE, type MediaService } from '../../contract/media-service';
import { MediaJobs } from '../worker/media-jobs';

const jpeg = new Uint8Array(1024).fill(0xff);

// The audit module is ported in parallel; this stand-in keeps what media records.
const audited: AuditEntry[] = [];
const audit = {
  record: (e: AuditEntry) => Promise.resolve(void audited.push(e)),
  listForSubject: () => Promise.resolve(audited),
};

interface Ticket {
  mediaId: string;
  uploadUrl: string;
  headers: Record<string, string>;
}

describe('media API', () => {
  let api: TestApi;

  beforeAll(async () => {
    api = await startTestApi({ imports: [standIn(new Map([[AUDIT_SERVICE, audit]]))] });
  });

  async function ticketFor(token: string, app: string, body: object): Promise<Ticket> {
    const r = await api.do('POST', `/v1/${app}/uploads`, body, { token });
    expect(r.status).toBe(201);
    return r.body as unknown as Ticket;
  }

  const put = (t: Ticket, body: Uint8Array) =>
    putFile({ url: t.uploadUrl, headers: t.headers }, body);
  const jpegOf = (purpose: string, size = jpeg.length) => ({
    purpose,
    contentType: 'image/jpeg',
    sizeBytes: size,
  });

  it('serves its operations with the spec permissions', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    expect(report.unserved.filter((op) => /uploads|documents/.test(op))).toEqual([]);
  });

  it('uploads, confirms and shows a provider document with an audit entry', async () => {
    const provider = (await signIn(api, '01712345601', 'partner')).accessToken;
    const ticket = await ticketFor(provider, 'provider', jpegOf('nid_front'));
    const confirm = `/v1/provider/uploads/${ticket.mediaId}/confirm`;
    expect((await api.do('POST', confirm, undefined, { token: provider })).code).toBe(
      'UPLOAD_NOT_FOUND',
    );
    expect(await put(ticket, jpeg)).toBe(200);
    for (let i = 0; i < 2; i++) {
      const r = await api.do('POST', confirm, undefined, { token: provider });
      expect(r).toMatchObject({ status: 200, body: { status: 'confirmed' } });
    }
    const other = (await signIn(api, '01712345602', 'partner')).accessToken;
    expect((await api.do('POST', confirm, undefined, { token: other })).status).toBe(404);
    const session = await adminSession(api, ['verifier']);
    const [verifierId, verifier] = [session.id, session.accessToken];
    const view = await api.do('GET', `/v1/admin/documents/${ticket.mediaId}/view-url`, undefined, {
      token: verifier,
    });
    expect(view.status).toBe(200);
    const download = await fetch(view.body?.url as string);
    expect(download.status).toBe(200);
    await download.arrayBuffer();
    expect(audited).toMatchObject([
      {
        action: 'media.document_viewed',
        actorId: verifierId,
        actorRole: 'verifier',
        subjectId: ticket.mediaId,
      },
    ]);
    const unknown = await api.do('GET', `/v1/admin/documents/${uuidv4()}/view-url`, undefined, {
      token: verifier,
    });
    expect(unknown.status).toBe(404);
  });

  it('enforces the upload rules of each app', async () => {
    const customer = (await signIn(api, '01712345603', 'customer')).accessToken;
    const ticket = await ticketFor(customer, 'customer', jpegOf('avatar'));
    expect(await put(ticket, jpeg.slice(0, 10))).toBe(403);
    const refused = [
      jpegOf('nid_front', 10),
      { purpose: 'avatar', contentType: 'application/pdf', sizeBytes: 10 },
      { purpose: 'avatar', contentType: 'image/png', sizeBytes: 3 << 20 },
    ];
    for (const body of refused) {
      const r = await api.do('POST', '/v1/customer/uploads', body, { token: customer });
      expect([body, r.code]).toEqual([body, 'UPLOAD_INVALID']);
    }
    const unknown = await api.do('POST', `/v1/customer/uploads/${uuidv4()}/confirm`, undefined, {
      token: customer,
    });
    expect(unknown.status).toBe(404);
    const provider = await api.token(uuidv4(), ['provider']);
    const level2 = await api.do('POST', '/v1/provider/uploads', jpegOf('level2_photo', 10), {
      token: provider,
    });
    expect(level2.code).toBe('UPLOAD_INVALID');
    const photo = await ticketFor(customer, 'customer', jpegOf('complaint_photo'));
    expect(await put(photo, jpeg)).toBe(200);
    const confirmed = await api.do(
      'POST',
      `/v1/customer/uploads/${photo.mediaId}/confirm`,
      undefined,
      { token: customer },
    );
    expect(confirmed.status).toBe(200);
  });

  it('serves the contract and purges orphans', async () => {
    const media = api.app.get<symbol, MediaService>(MEDIA_SERVICE, { strict: false });
    const ownerId = uuidv4();
    const req = {
      ownerId,
      purpose: 'level2_photo',
      contentType: 'image/jpeg',
      sizeBytes: jpeg.length,
    } as const;
    const kept = await media.createUploadUrl(req);
    expect(await putFile(kept, jpeg)).toBe(200);
    expect(await media.confirmUpload(ownerId, kept.mediaId)).toMatchObject({ confirmed: true });
    await media.markAttached(kept.mediaId);
    const orphan = await media.createUploadUrl(req);
    await expect(media.createUploadUrl({ ...req, purpose: 'avatar' })).rejects.toMatchObject({
      reason: 'media.upload_invalid',
    });
    await expect(media.confirmUpload(ownerId, orphan.mediaId)).rejects.toMatchObject({
      reason: 'media.not_uploaded',
    });
    await expect(
      media.getViewUrl({ mediaId: orphan.mediaId, viewerId: ownerId, viewerRole: 'v' }),
    ).rejects.toThrow();
    const selfie = await upload(api, ownerId, 'provider', 'selfie');
    await media.markAttached(selfie);
    api.clock.advance(25 * 60 * 60_000);
    const jobs = new JobScheduler(api.app.get(DATABASE), api.clock, discardLogger());
    api.app.get(MediaJobs, { strict: false }).schedule(jobs);
    expect(await jobs.runNow('media.purge_orphans')).toBe(true);
    await expect(media.getObject(orphan.mediaId)).rejects.toMatchObject({
      reason: 'media.not_found',
    });
    expect((await media.getObject(kept.mediaId)).purpose).toBe('level2_photo');
    await media.delete(kept.mediaId);
    await expect(media.markAttached(kept.mediaId)).rejects.toMatchObject({
      reason: 'media.not_found',
    });
    await expect(media.delete(kept.mediaId)).rejects.toMatchObject({ reason: 'media.not_found' });
  });

  it('answers 500 when the database is gone, after checking the rules', async () => {
    const customer = await api.token(uuidv4(), ['customer']);
    const provider = await api.token(uuidv4(), ['provider']);
    await api.do('POST', `/v1/provider/uploads/${uuidv4()}/confirm`, undefined, {
      token: provider,
    });
    await api.do('POST', `/v1/customer/uploads/${uuidv4()}/confirm`, undefined, {
      token: customer,
    });
    await api.app.get<symbol, Database>(DATABASE).close();
    const invalid = await api.do('POST', '/v1/customer/uploads', jpegOf('nid_front', 10), {
      token: customer,
    });
    expect(invalid.status).toBe(422);
    expect(
      (await api.do('POST', '/v1/provider/uploads', jpegOf('avatar', 10), { token: provider }))
        .status,
    ).toBe(500);
    const confirm = await api.do('POST', `/v1/provider/uploads/${uuidv4()}/confirm`, undefined, {
      token: provider,
    });
    expect(confirm.status).toBe(500);
  });
});
