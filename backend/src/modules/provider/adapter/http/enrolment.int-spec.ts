import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { lastCode, signIn } from '../../../../../test/kit/identity';
import { upload } from '../../../../../test/kit/media';
import { enrol, personal, service } from '../../../../../test/kit/provider';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { PROVIDER_SERVICE, ProviderErrors, type ProviderService } from '../../contract';

const PHONE = '01712345678';
const electrician = service('electrician');

describe('provider enrolment', () => {
  let api: TestApi;
  let providers: ProviderService;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
    providers = api.app.get(PROVIDER_SERVICE);
  });

  it('serves every provider operation with the spec permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = new Set([
      'getEnrolment',
      'savePersonalStep',
      'saveServicesStep',
      'saveAreaStep',
      'saveEmergencyContactStep',
      'verifyEmergencyContact',
      'saveCodeOfConductStep',
      'getProviderProfile',
      'updateProviderProfile',
      'goOnline',
      'goOffline',
      'sendHeartbeat',
      'getProviderPublicProfile',
    ]);
    expect(report.unserved.filter((op) => ours.has(op.split(' ').at(-1) ?? ''))).toEqual([]);
  });

  it('keeps the wizard resumable (TestEnrolment_WizardIsResumable)', async () => {
    const { id, token } = await enrol(api, PHONE, 'male', electrician);
    const contact = { name: 'Karim Uddin', relation: 'Brother', phone: '01812345678' };
    const verify = '/v1/provider/enrolment/emergency-contact/verify';
    expect(
      (await api.do('PUT', '/v1/provider/enrolment/emergency-contact', contact, { token })).status,
    ).toBe(200);
    expect((await api.do('POST', verify, { code: '000000' }, { token })).code).toBe('OTP_INVALID');
    const r = await api.do('POST', verify, { code: lastCode(api, '01812345678') }, { token });
    expect(r.status).toBe(200);
    const steps = r.body?.steps as { step: string; done: boolean }[];
    const done = Object.fromEntries(steps.map((s) => [s.step, s.done]));
    expect(done).toMatchObject({ personal: true, emergency_contact: true, nid: false });
    expect(r.body?.complete).toBe(false);
    const resumed = await api.do('GET', '/v1/provider/enrolment', undefined, { token });
    expect(resumed.body?.steps).toHaveLength(9);
    await expect(providers.markSubmitted(id)).rejects.toMatchObject({
      reason: ProviderErrors.EnrolmentIncomplete,
    });
    for (const s of ['nid', 'selfie', 'police_clearance'] as const) {
      await providers.markStepDone(id, s);
    }
    await providers.markSubmitted(id);
    expect(await providers.enrolment(id)).toMatchObject({ complete: true, submitted: true });
    const p = await providers.getProvider(id);
    expect(p).toMatchObject({ fullName: 'Rahim Uddin', homeBase: { lat: 23.7937 } });
    expect(p.emergencyContact?.phone).toBe('+8801812345678');
    expect(p.dateOfBirth?.toISOString()).toBe('1990-04-12T00:00:00.000Z');
    await expect(providers.getProvider(uuid())).rejects.toMatchObject({
      reason: ProviderErrors.NotFound,
    });
    expect((await providers.enrolment(uuid())).complete).toBe(false);
    const query = {
      id: null,
      status: 'pending',
      level: 0,
      flagged: false,
      afterAt: null,
      afterId: null,
      limit: 5,
    };
    const found = await providers.searchProviders({ ...query, text: ' RAHIM ' });
    expect(found.map((r) => [r.id, r.serviceIds, r.online])).toEqual([[id, [electrician], false]]);
    expect(await providers.searchProviders({ ...query, text: 'rahim_%\\' })).toEqual([]);
    const after = { ...query, text: '', afterAt: new Date(), afterId: uuid() };
    expect(await providers.searchProviders(after)).toHaveLength(1);
  });

  it('validates each step (TestEnrolment_Validation)', async () => {
    const token = (await signIn(api, PHONE, 'partner')).accessToken;
    const cases: [string, unknown, string][] = [
      ['personal', { ...personal('male'), dateOfBirth: '2015-01-01' }, 'AGE_REQUIREMENT'],
      ['personal', { ...personal('male'), presentAddress: '     ' }, 'VALIDATION_FAILED'],
      ['services', { serviceIds: [uuid()], experienceYears: 1 }, 'SERVICE_UNAVAILABLE'],
      ['area', { homeBase: { lat: 51.5, lng: 0 }, workingRadiusM: 5000 }, 'VALIDATION_FAILED'],
      ['emergency-contact', { name: 'Me', relation: 'Self', phone: PHONE }, 'VALIDATION_FAILED'],
      ['code-of-conduct', { version: '2026-10', accepted: false }, 'VALIDATION_FAILED'],
    ];
    for (const [step, body, code] of cases) {
      expect((await api.do('PUT', `/v1/provider/enrolment/${step}`, body, { token })).code).toBe(
        code,
      );
    }
    const verify = '/v1/provider/enrolment/emergency-contact/verify';
    expect((await api.do('POST', verify, { code: '123456' }, { token })).code).toBe(
      'EMERGENCY_CONTACT_MISSING',
    );
    const contact = { name: 'Karim Uddin', relation: 'Brother', phone: '01812345678' };
    await api.do('PUT', '/v1/provider/enrolment/emergency-contact', contact, { token });
    const again = await api.do('PUT', '/v1/provider/enrolment/emergency-contact', contact, {
      token,
    });
    expect(again.code).toBe('RATE_LIMITED');
  });

  it('sets the photo and language (TestProfile_PhotoAndLanguage)', async () => {
    const { id, token } = await enrol(api, PHONE, 'male', electrician);
    const photo = await upload(api, id, 'provider', 'avatar');
    const body = { bio: 'Licensed', language: 'en', photoMediaId: photo };
    const r = await api.do('PUT', '/v1/provider/profile', body, { token });
    expect(r.status).toBe(200);
    expect(r.body).toMatchObject({ language: 'en', badge: 'none', homeBase: { lat: 23.7937 } });
    expect(r.body?.photoUrl).toBeDefined();
    expect(r.body?.services).toHaveLength(1);
    const unknown = { language: 'bn', photoMediaId: uuid() };
    expect((await api.do('PUT', '/v1/provider/profile', unknown, { token })).code).toBe(
      'UPLOAD_INVALID',
    );
    const other = (await signIn(api, '01912345678', 'partner')).accessToken;
    const fresh = await api.do('GET', '/v1/provider/profile', undefined, { token: other });
    expect(fresh).toMatchObject({ status: 200, body: { name: '' } });
    const update = await api.do(
      'PUT',
      '/v1/provider/profile',
      { language: 'en' },
      { token: other },
    );
    expect(update.status).toBe(200);
  });
});
