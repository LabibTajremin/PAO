import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { deliver, envelope, subscribedBus } from '../../../../../test/kit/events';
import { adminSession, signIn } from '../../../../../test/kit/identity';
import { upload } from '../../../../../test/kit/media';
import { enrolledProvider, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { VERIFICATION_SERVICE, type VerificationService } from '../../contract';

const electrician = service('electrician');
const date = (d: Date) => d.toISOString().slice(0, 10);

describe('verification failures', () => {
  let api: TestApi;
  let verifier: string;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
    verifier = (await adminSession(api, ['verifier'])).accessToken;
  });

  it('validates the document steps (TestDocuments_Validation)', async () => {
    const tp = await signIn(api, '01712345678', 'partner');
    const me = { token: tp.accessToken };
    const selfie = await upload(api, tp.account.id, 'provider', 'selfie');
    const foreign = await upload(api, uuid(), 'provider', 'selfie');
    const old = new Date(api.clock.now());
    old.setUTCFullYear(old.getUTCFullYear() - 2);
    const today = date(api.clock.now());
    const cases: [string, unknown, string][] = [
      ['selfie', { mediaId: foreign }, 'UPLOAD_INVALID'],
      ['selfie', { mediaId: uuid() }, 'UPLOAD_INVALID'],
      ['police-clearance', { mediaId: selfie, issueDate: today }, 'UPLOAD_INVALID'],
      ['police-clearance', { mediaId: selfie, issueDate: date(old) }, 'CLEARANCE_TOO_OLD'],
      ['skill-proof', { mediaIds: [] }, 'VALIDATION_FAILED'],
      ['nid', { nidNumber: '12', frontMediaId: selfie, backMediaId: selfie }, 'VALIDATION_FAILED'],
    ];
    for (const [step, body, code] of cases) {
      expect((await api.do('PUT', `/v1/provider/enrolment/${step}`, body, me)).code).toBe(code);
    }
    const proof = await upload(api, tp.account.id, 'provider', 'skill_proof');
    const saved = await api.do(
      'PUT',
      '/v1/provider/enrolment/skill-proof',
      { mediaIds: [proof] },
      me,
    );
    expect(saved.status).toBe(200);
    expect((await api.do('POST', '/v1/provider/enrolment/submit', undefined, me)).code).toBe(
      'ENROLMENT_INCOMPLETE',
    );
    const auth = { token: verifier };
    expect((await api.do('GET', `/v1/admin/verifications/${uuid()}`, undefined, auth)).status).toBe(
      404,
    );
    const blank = await api.do(
      'POST',
      `/v1/admin/verifications/${tp.account.id}/items/nid/reject`,
      { reason: '   ' },
      auth,
    );
    expect(blank.status).toBe(422);
    expect(
      (await api.do('GET', '/v1/admin/verifications?cursor=%25', undefined, auth)).status,
    ).toBe(422);
  });

  it('pages the queue and fails without stores (TestQueue_PagingAndFailures)', async () => {
    const first = await enrolledProvider(api, '01712345601', 'male', electrician);
    api.clock.advance(60_000);
    await enrolledProvider(api, '01712345602', 'male', electrician);
    const auth = { token: verifier };
    const page = await api.do('GET', '/v1/admin/verifications?limit=1', undefined, auth);
    const items = page.body?.items as { providerId: string }[];
    expect(items.map((i) => i.providerId)).toEqual([first.id]);
    const cursor = page.body?.nextCursor as string;
    const next = await api.do(
      'GET',
      `/v1/admin/verifications?limit=1&cursor=${cursor}`,
      undefined,
      auth,
    );
    expect(next.body?.items).toHaveLength(1);
    expect(next.body?.nextCursor).toBeUndefined();
    const bus = subscribedBus(api);
    for (const name of ['provider.EnrolmentStepSaved', 'identity.AccountStatusChanged']) {
      const e = { name } as DomainEvent;
      const broken = { ...envelope(api, e), payload: 'not json' as never };
      await expect(bus.dispatch(broken)).rejects.toThrow('payload is not an object');
    }
    const saved = { name: 'provider.EnrolmentStepSaved', providerId: first.id, step: 'nid' };
    await deliver(api, saved);
    expect((await api.do('GET', '/v1/admin/level2-sessions', undefined, auth)).status).toBe(200);
    await api.app.get<Database>(DATABASE).pool.end();
    for (const [path, token] of [
      ['/v1/admin/verifications', verifier],
      ['/v1/admin/level2-sessions', verifier],
      ['/v1/provider/verification', first.token],
    ] as const) {
      expect((await api.do('GET', path, undefined, { token })).status).toBe(500);
    }
    const verification = api.app.get<VerificationService>(VERIFICATION_SERVICE);
    await expect(verification.getLevel(first.id)).rejects.toThrow();
  });
});
