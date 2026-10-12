import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { relayEvents } from '../../../../../test/kit/events';
import { adminSession, signIn } from '../../../../../test/kit/identity';
import { upload } from '../../../../../test/kit/media';
import {
  enrolledProvider,
  near,
  service,
  verifiedProvider,
} from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { AUDIT_SERVICE, type AuditService } from '../../../audit/contract';
import { IDENTITY_SERVICE, type IdentityService } from '../../../identity/contract';
import { VERIFICATION_SERVICE, type VerificationService } from '../../contract';

const electrician = service('electrician');
const APPROVED = ['nid', 'selfie', 'police_clearance', 'address', 'emergency_contact'];
const ALL = [...APPROVED, 'service_area', 'code_of_conduct'];

describe('verification flow', () => {
  let api: TestApi;
  let verification: VerificationService;
  let verifier: string;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
    verification = api.app.get(VERIFICATION_SERVICE);
    verifier = (await adminSession(api, ['verifier'])).accessToken;
  });

  it('serves every verification operation with the spec permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    const ours =
      /\/v1\/admin\/(verifications|level2-sessions)|enrolment\/(nid|selfie|police|skill|submit)|\/v1\/provider\/verification/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  it('takes an enrolment to Level 1 (TestVerification_FullEnrolmentToLevelOne)', async () => {
    const p = await enrolledProvider(api, '01712345678', 'male', electrician);
    const me = { token: p.token };
    expect((await api.do('GET', '/v1/me/permissions', undefined, me)).status).toBe(200);
    const auth = { token: verifier };
    const q = await api.do(
      'GET',
      `/v1/admin/verifications?serviceId=${electrician}&itemType=nid`,
      undefined,
      auth,
    );
    const items = q.body?.items as { name: string; pendingItems: string[] }[];
    expect(items).toHaveLength(1);
    expect(items[0]?.name).toBe('Rahim Uddin');
    expect(items[0]?.pendingItems).toHaveLength(7);
    const skill = await api.do(
      'GET',
      '/v1/admin/verifications?itemType=skill_proof',
      undefined,
      auth,
    );
    expect(skill.body?.items).toEqual([]);
    const path = `/v1/admin/verifications/${p.id}`;
    const r = await api.do('GET', path, undefined, auth);
    expect(r.body).toMatchObject({
      profile: { nidNumber: '1712345678' },
      faceMatch: 'manual_review',
    });
    const reject = await api.do(
      'POST',
      `${path}/items/selfie/reject`,
      { reason: 'Face not visible' },
      auth,
    );
    expect(reject.status).toBe(200);
    const status = await api.do('GET', '/v1/provider/verification', undefined, me);
    expect(status.body).toMatchObject({ level: 0, canReceiveBookings: false });
    expect((await api.do('POST', `${path}/items/selfie/approve`, undefined, auth)).code).toBe(
      'ITEM_NOT_PENDING',
    );
    const selfie = { mediaId: await upload(api, p.id, 'provider', 'selfie') };
    await api.do('PUT', '/v1/provider/enrolment/selfie', selfie, me);
    for (const item of ALL) {
      expect((await api.do('POST', `${path}/items/${item}/approve`, undefined, auth)).status).toBe(
        200,
      );
    }
    await relayEvents(api);
    const level1 = await api.do('GET', '/v1/provider/verification', undefined, me);
    expect(level1.body).toMatchObject({
      level: 1,
      badge: 'verified',
      canReceiveBookings: true,
      level2: { eligible: true },
    });
    expect((await api.do('POST', '/v1/provider/presence/online', near, me)).status).toBe(200);
    expect(await verification.canReceiveBookings(p.id, electrician)).toBe(true);
    expect(await verification.getLevel(uuid())).toBe(0);
    await api.app
      .get<Database>(DATABASE)
      .query('UPDATE catalog.services SET requires_level_2 = true WHERE id = $1', [electrician]);
    expect(await verification.canReceiveBookings(p.id, electrician)).toBe(false);
    const levels = await verification.getLevels([p.id, uuid()]);
    expect([...levels]).toEqual([[p.id, 1]]);
    expect(await verification.getItems(p.id)).toHaveLength(7);
    expect(await verification.countPendingReviews()).toBe(0);
    const audit = api.app.get<AuditService>(AUDIT_SERVICE);
    expect(await audit.listForSubject('provider', p.id, 50)).toHaveLength(9);
    const reviewed = r.body?.items as { documents: { mediaId: string }[] }[];
    const doc = reviewed[0]?.documents[0]?.mediaId ?? '';
    expect(
      (await api.do('GET', `/v1/admin/documents/${doc}/view-url`, undefined, auth)).status,
    ).toBe(200);
  });

  it('blocks a banned NID and bookings (TestBan_BlocksNIDAndBookings)', async () => {
    const p = await verifiedProvider(api, '01712345678', 'male', electrician);
    const root = await adminSession(api, ['super_admin']);
    const identity = api.app.get<IdentityService>(IDENTITY_SERVICE);
    await identity.setAccountStatus({
      accountId: p.id,
      status: 'banned',
      reason: 'fraud',
      actorId: root.id,
    });
    await relayEvents(api);
    expect(await verification.canReceiveBookings(p.id, null)).toBe(false);
    const other = await signIn(api, '01812345678', 'partner');
    const nid = {
      nidNumber: '1712345678',
      frontMediaId: await upload(api, other.account.id, 'provider', 'nid_front'),
      backMediaId: await upload(api, other.account.id, 'provider', 'nid_back'),
    };
    const r = await api.do('PUT', '/v1/provider/enrolment/nid', nid, { token: other.accessToken });
    expect(r.code).toBe('NID_BLOCKED');
  });
});
