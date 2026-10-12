import {
  approveAll,
  boom,
  enrolled,
  verificationFixture,
} from '../../../../test/fakes/verification';
import { DomainError } from '../../../platform/errors/domain-error';
import { VerificationEvents } from '../contract/events';
import { VerificationReasons } from '../domain/reasons';
import { REMINDER_DAYS } from './expiry';

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const reason = (r: string) => ({ reason: r });
const outcome = { checklist: [], notes: '', visitLat: null, visitLng: null, photos: [] };

async function levelOne() {
  const f = verificationFixture();
  await enrolled(f);
  await approveAll(f);
  return f;
}

describe('Level 2 sessions', () => {
  it('schedules, fails, cools off and passes', async () => {
    const f = await levelOne();
    const later = (ms: number) => new Date(f.clock.now().getTime() + ms);
    const book = { providerId: f.id, serviceId: 'svc', at: later(48 * HOUR), location: 'Office' };
    await expect(f.level2.schedule({ ...book, at: later(-HOUR) })).rejects.toMatchObject(
      reason(VerificationReasons.Invalid),
    );
    await expect(f.level2.schedule({ ...book, providerId: 'stranger' })).rejects.toMatchObject(
      reason(VerificationReasons.NotEligible),
    );
    const s = await f.level2.schedule({ ...book, location: ' PAO office, Gulshan 1 ' });
    expect(s.location).toBe('PAO office, Gulshan 1');
    const st = await f.status.status(f.id);
    expect(st.nextSession?.id).toBe(s.id);
    expect(st.level2Eligible).toBe(true);
    await f.level2.record(s.id, 'v', { ...outcome, result: 'fail', photos: ['photo'] });
    await expect(f.level2.schedule(book)).rejects.toMatchObject(
      reason(VerificationReasons.CoolingOff),
    );
    const cooling = await f.status.status(f.id);
    expect(cooling.retryAfter).not.toBeNull();
    expect(cooling.level2Eligible).toBe(false);
    f.clock.advance(15 * DAY);
    const retry = await f.level2.schedule({ ...book, at: later(HOUR) });
    const checklist = [{ item: 'Safe wiring', passed: true }];
    const passed = await f.level2.record(retry.id, 'v', { ...outcome, result: 'pass', checklist });
    expect(passed).toMatchObject({ result: 'pass', decidedBy: 'v' });
    expect(await f.states.level(f.id)).toBe(2);
    await expect(
      f.level2.record(retry.id, 'v', { ...outcome, result: 'pass' }),
    ).rejects.toMatchObject(reason(VerificationReasons.SessionClosed));
    await expect(
      f.level2.record('nope', 'v', { ...outcome, result: 'pass' }),
    ).rejects.toMatchObject(reason(VerificationReasons.NotFound));
    expect((await f.level2.get(retry.id)).id).toBe(retry.id);
    expect(
      await f.level2.list({ providerId: null, status: null }, { at: null, id: null, limit: 21 }),
    ).toEqual([]);
    f.peers.err = boom;
    await expect(f.level2.schedule({ ...book, at: later(HOUR) })).rejects.toBe(boom);
    f.peers.err = undefined;
    f.peers.mediaErr = new DomainError(VerificationReasons.BadDocument);
    const withPhoto = { ...outcome, result: 'pass', photos: ['p'] };
    await expect(f.level2.record(retry.id, 'v', withPhoto)).rejects.toBe(f.peers.mediaErr);
  });
});

describe('document expiry', () => {
  it('reminds once per threshold, then drops the level', async () => {
    const f = await levelOne();
    const expiresAt =
      f.repo.states.get(f.id)?.items.get('police_clearance')?.expiresAt ?? new Date(0);
    f.repo.expiring = [{ providerId: f.id, itemType: 'police_clearance', expiresAt }];
    await f.expiry.remindExpiring();
    await f.expiry.remindExpiring();
    const reminders = f.repo.events.filter((e) => e.name === VerificationEvents.DocumentExpiring);
    expect(reminders).toHaveLength(REMINDER_DAYS.length);
    await f.expiry.expireDocuments();
    expect(f.repo.states.get(f.id)?.level).toBe(1);
    f.clock.set(expiresAt);
    await f.expiry.expireDocuments();
    const st = f.repo.states.get(f.id);
    expect(st?.level).toBe(0);
    expect(st?.items.get('police_clearance')?.status).toBe('expired');
    f.repo.listErr = boom;
    await expect(f.expiry.expireDocuments()).rejects.toBe(boom);
    await expect(f.expiry.remindExpiring()).rejects.toBe(boom);
    f.repo.listErr = undefined;
    f.repo.err = boom;
    await expect(f.expiry.remindExpiring()).rejects.toBe(boom);
  });
});

describe('account status', () => {
  it('blocks suspended providers and bans their NID', async () => {
    const f = await levelOne();
    await f.changes.onAccountStatus(f.id, 'suspended');
    expect(await f.states.canReceiveBookings(f.id, null)).toBe(false);
    await f.changes.onAccountStatus(f.id, 'banned');
    expect(f.repo.blocked.has('h:1234567890')).toBe(true);
    await f.changes.onAccountStatus(f.id, 'active');
    expect(await f.states.canReceiveBookings(f.id, null)).toBe(true);
    f.peers.err = boom;
    await expect(f.states.canReceiveBookings(f.id, 'svc')).rejects.toBe(boom);
  });
});
