import type Redis from 'ioredis';
import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { REDIS } from '../../../../platform/redis/redis-client';
import { ADMIN_SERVICE, type AdminService } from '../../contract';

const RADIUS = '/v1/admin/settings/search.default_radius_m';

describe('admin settings', () => {
  let api: TestApi;
  let admin: AdminService;
  let db: Database;
  let superId: string;
  let superAdmin: string;
  let catalog: string;

  beforeAll(async () => {
    api = await startTestApi();
    admin = api.app.get(ADMIN_SERVICE);
    db = api.app.get(DATABASE);
    superId = uuid();
    superAdmin = await api.token(superId, ['super_admin']);
    catalog = await api.token(uuid(), ['catalog_manager']);
  });

  it('applies an update at once and records it for the audit trail', async () => {
    const s = await admin.getSettings();
    expect(s).toMatchObject({
      defaultSearchRadiusM: 5000,
      acceptTimeoutAsapMs: 180_000,
      ratingFloor: 3.5,
      documentRetentionMs: 365 * 86_400_000,
    });
    const r = await api.do('PUT', RADIUS, { value: '7000' }, { token: superAdmin });
    expect(r).toMatchObject({ status: 200, body: { value: '7000', updatedBy: superId } });
    expect((await admin.getSettings()).defaultSearchRadiusM).toBe(7000);
    const events = await db.query<{ payload: Record<string, unknown> }>(
      `SELECT payload FROM admin.outbox WHERE event_name = 'admin.SettingChanged'`,
    );
    expect(events.rows.map((e) => e.payload)).toEqual([
      {
        name: 'admin.SettingChanged',
        key: 'search.default_radius_m',
        before: '5000',
        after: '7000',
        actorId: superId,
      },
    ]);
    const list = await api.do('GET', '/v1/admin/settings', undefined, { token: superAdmin });
    expect(list.status).toBe(200);
    expect(list.body?.items).toHaveLength(12);
    expect(await admin.countVerifiedComplaints(uuid())).toBe(0);
  });

  it('refuses bad values, unknown keys and missing permissions', async () => {
    const bad = await api.do('PUT', RADIUS, { value: 'far' }, { token: superAdmin });
    expect(bad).toMatchObject({ status: 422, code: 'SETTING_INVALID' });
    const unknown = await api.do(
      'PUT',
      '/v1/admin/settings/no.such_key',
      { value: '1' },
      {
        token: superAdmin,
      },
    );
    expect(unknown.status).toBe(404);
    expect((await api.do('GET', '/v1/admin/settings', undefined, { token: catalog })).status).toBe(
      200,
    );
    expect((await api.do('PUT', RADIUS, { value: '1' }, { token: catalog })).status).toBe(403);
  });

  it('falls back to defaults for damaged rows and fails without a database', async () => {
    await db.query(`UPDATE admin.settings SET value = 'x' WHERE type IN ('integer', 'number')`);
    await api.app.get<Redis>(REDIS).del(api.keys.key('cache', 'settings'));
    expect(await admin.getSettings()).toMatchObject({ ratingFloor: 3.5, startCodeMaxAttempts: 5 });
    await api.app.get<Redis>(REDIS).del(api.keys.key('cache', 'settings'));
    await db.close();
    const list = await api.do('GET', '/v1/admin/settings', undefined, { token: superAdmin });
    expect(list.status).toBe(500);
    expect((await api.do('PUT', RADIUS, { value: '1' }, { token: superAdmin })).status).toBe(500);
    await expect(admin.getSettings()).rejects.toThrow();
  });
});
