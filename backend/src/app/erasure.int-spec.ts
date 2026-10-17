// Account deletion erases personal data in every module (PRD §11), and verification
// documents outlive the account only by the retention period (PRD §6.6, ADR-0023).
import { randomUUID } from 'node:crypto';
import { startTestApi, type TestApi } from '../../test/kit/api';
import { completedJob, type Job } from '../../test/kit/booking';
import { relayEvents } from '../../test/kit/events';
import { lastCode } from '../../test/kit/identity';
import { upload } from '../../test/kit/media';
import { VerificationWorker } from '../modules/verification/adapter/inproc/worker-hooks';
import { DocumentRetention } from '../modules/verification/app/retention';
import { DATABASE, type Database } from '../platform/db/database';
import { type JobScheduler } from '../platform/jobs/scheduler';

const DAY_MS = 24 * 60 * 60_000;
const CUSTOMER_PHONE = '01812345671';
const PROVIDER_PHONE = '01712345672';

describe('account deletion', () => {
  let api: TestApi;
  let db: Database;
  let job: Job;

  const one = async (sql: string, ...args: unknown[]) =>
    (await db.pool.query(sql, args)).rows[0] as Record<string, unknown> | undefined;
  const count = async (sql: string, ...args: unknown[]) =>
    Number((await one(`SELECT count(*) AS n FROM ${sql}`, ...args))?.n);

  async function deleteAccount(phone: string, token: string): Promise<void> {
    api.clock.advance(60_000);
    await api.do('POST', '/v1/auth/otp/request', { phone, purpose: 'delete_account' });
    const del = await api.do('DELETE', '/v1/me', { code: lastCode(api, phone) }, { token });
    expect(del.status).toBe(204);
    await relayEvents(api);
  }

  beforeAll(async () => {
    api = await startTestApi();
    db = api.app.get(DATABASE);
    job = await completedJob(api, PROVIDER_PHONE, CUSTOMER_PHONE);
    const review = { stars: 5, comment: 'Lovely work, call me on 01812345671' };
    const path = `/v1/customer/bookings/${job.id}/review`;
    expect((await api.do('POST', path, review, { token: job.customer.token })).status).toBe(201);
    const back = { stars: 4, comment: 'Kind host' };
    const jobPath = `/v1/provider/jobs/${job.id}/review`;
    expect((await api.do('POST', jobPath, back, { token: job.provider.token })).status).toBe(201);
    await upload(api, job.customer.id, 'customer', 'avatar');
    await relayEvents(api);
  });

  it("blanks the customer's details everywhere and keeps the shared history", async () => {
    await deleteAccount(CUSTOMER_PHONE, job.customer.token);
    const id = job.customer.id;
    expect(await one('SELECT phone FROM identity.accounts WHERE id = $1', id)).toEqual({
      phone: null,
    });
    expect(await count('customer.customers WHERE id = $1', id)).toBe(0);
    expect(await count('customer.addresses WHERE customer_id = $1', id)).toBe(0);
    expect(await count('notification.notifications WHERE recipient_id = $1', id)).toBe(0);
    expect(await count('media.objects WHERE owner_id = $1', id)).toBe(0);
    const booking = await one(
      `SELECT customer_name, customer_phone, address_line1, address_line2, note,
              provider_name, ST_Y(address_location::geometry) AS lat
       FROM booking.bookings WHERE id = $1`,
      job.id,
    );
    expect(booking).toMatchObject({
      customer_name: '',
      customer_phone: '',
      address_line1: '',
      address_line2: '',
      note: '',
    });
    expect(booking?.provider_name).not.toBe('');
    // The pin is coarsened to about a kilometre: the area stays for statistics.
    const lat = (booking?.lat as number) * 100;
    expect(Math.abs(lat - Math.round(lat))).toBeLessThan(1e-6);
    expect(
      await one('SELECT author_name, comment, stars FROM rating.reviews WHERE author_id = $1', id),
    ).toEqual({ author_name: '', comment: '', stars: 5 });
    expect(
      await one(
        'SELECT customer_name FROM rating.reviewable_bookings WHERE booking_id = $1',
        job.id,
      ),
    ).toEqual({ customer_name: '' });
    const kept = await one(
      'SELECT comment FROM rating.reviews WHERE author_id = $1',
      job.provider.id,
    );
    expect(kept).toEqual({ comment: 'Kind host' });
  });

  it("keeps the provider's documents for the retention period, then purges them", async () => {
    const id = job.provider.id;
    const photo = randomUUID();
    await db.pool.query(
      `INSERT INTO verification.level2_sessions
         (id, provider_id, service_id, scheduled_at, location, photo_media_ids)
       VALUES ($1, $2, $3, now(), 'Banani', ARRAY[$4::uuid])`,
      [randomUUID(), id, randomUUID(), photo],
    );
    const documents = await count('verification.documents WHERE provider_id = $1', id);
    expect(documents).toBeGreaterThan(0);
    await deleteAccount(PROVIDER_PHONE, job.provider.token);
    expect(await count('provider.providers WHERE id = $1', id)).toBe(0);
    expect(
      await one('SELECT provider_name, provider_phone FROM booking.bookings WHERE id = $1', job.id),
    ).toEqual({ provider_name: '', provider_phone: '' });
    expect(await count('verification.closed_accounts WHERE provider_id = $1', id)).toBe(1);
    expect(await count('verification.documents WHERE provider_id = $1', id)).toBe(documents);
    const files = await count('media.objects WHERE owner_id = $1', id);
    expect(files).toBeGreaterThan(0);

    const retention = api.app.get(DocumentRetention);
    api.clock.advance(364 * DAY_MS);
    expect(await retention.purgeExpired()).toBe(0);
    expect(await count('media.objects WHERE owner_id = $1', id)).toBe(files);
    api.clock.advance(2 * DAY_MS);
    // Through the scheduled job, as the worker runs it every night.
    const jobs: Record<string, () => Promise<void>> = {};
    const scheduler = {
      dailyAt: (_h: number, _m: number, name: string, job: () => Promise<void>) => {
        jobs[name] = job;
      },
    };
    api.app.get(VerificationWorker).schedule(scheduler as unknown as JobScheduler);
    await jobs['verification.purge_closed']?.();
    // The customer's closure, older still, had nothing to purge and is gone as well.
    expect(await count('verification.closed_accounts')).toBe(0);
    for (const table of ['items', 'documents', 'nid_records', 'levels', 'level2_sessions']) {
      expect(await count(`verification.${table} WHERE provider_id = $1`, id)).toBe(0);
    }
    expect(await count('verification.closed_accounts WHERE provider_id = $1', id)).toBe(0);
    expect(await count('media.objects WHERE owner_id = $1', id)).toBe(0);
  });
});
