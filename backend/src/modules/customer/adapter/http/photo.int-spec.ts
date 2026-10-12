import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { signIn } from '../../../../../test/kit/identity';
import { upload } from '../../../../../test/kit/media';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { CUSTOMER_SERVICE, type CustomerService } from '../../contract';

const PROFILE = '/v1/customer/profile';

describe('customer profile photo', () => {
  let api: TestApi;
  let customers: CustomerService;

  beforeAll(async () => {
    api = await startTestApi();
    customers = api.app.get(CUSTOMER_SERVICE);
  });

  // TestCustomer_ProfileWithPhotoAndDeletion, the photo steps.
  it('accepts only the customer own confirmed avatar', async () => {
    const tp = await signIn(api, '01712345678', 'customer');
    const token = tp.accessToken;
    const unknown = { name: 'Nusrat', language: 'bn', photoMediaId: uuid() };
    expect((await api.do('PUT', PROFILE, unknown, { token })).code).toBe('UPLOAD_INVALID');

    const photo = await upload(api, tp.account.id, 'customer', 'avatar');
    const body = { name: 'Nusrat', language: 'en', photoMediaId: photo };
    const saved = await api.do('PUT', PROFILE, body, { token });
    expect(saved).toMatchObject({ status: 200, body: { phone: '+8801712345678' } });
    expect(saved.body?.photoUrl).toEqual(expect.any(String));
    expect((await api.do('GET', PROFILE, undefined, { token })).body?.photoUrl).toEqual(
      expect.any(String),
    );
    expect(await customers.getCustomer(tp.account.id)).toMatchObject({ photoMediaId: photo });

    const other = await upload(api, uuid(), 'customer', 'avatar');
    const theirs = { name: 'Nusrat', language: 'bn', photoMediaId: other };
    expect((await api.do('PUT', PROFILE, theirs, { token })).code).toBe('UPLOAD_INVALID');
  });

  // TestCustomer_ContractAndPeerFailures, the media steps.
  it('refuses a level 2 photo as an avatar and fails when the photo lookup breaks', async () => {
    const id = uuid();
    const token = await api.token(id, ['customer']);
    const level2 = await upload(api, id, 'admin', 'level2_photo');
    const body = { name: 'Nusrat', language: 'bn', photoMediaId: level2 };
    expect((await api.do('PUT', PROFILE, body, { token })).code).toBe('UPLOAD_INVALID');

    await api.app.get<Database>(DATABASE).close();
    const closed = { name: 'Nusrat', language: 'bn', photoMediaId: id };
    expect((await api.do('PUT', PROFILE, closed, { token })).status).toBe(500);
  });
});
