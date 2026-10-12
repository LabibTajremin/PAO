import {
  clearanceExpiry,
  decided,
  dhakaDate,
  hasExpired,
  type Item,
  ITEM_TYPES,
  level,
  missingItem,
  required,
  submitted,
  validNid,
} from './items';
import { recorded, retryAfter, type Session } from './level2';
import { VerificationReasons } from './reasons';
import { canReceiveBookings, itemOf, newState, recalc } from './state';

const now = new Date('2026-10-09T10:00:00Z');
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

function approvedAll(): Map<string, Item> {
  const items = new Map<string, Item>();
  for (const t of ITEM_TYPES.filter(required)) {
    items.set(t, { ...missingItem(t), status: 'approved' });
  }
  return items;
}

describe('verification domain', () => {
  it('needs every required item approved for a level', () => {
    expect(level(approvedAll(), false)).toBe(1);
    expect(level(approvedAll(), true)).toBe(2);
    for (const t of ITEM_TYPES.filter(required)) {
      for (const status of ['missing', 'pending', 'rejected', 'expired']) {
        const items = approvedAll();
        items.set(t, { ...missingItem(t), status });
        expect(level(items, true)).toBe(0);
      }
    }
  });

  it('runs the item lifecycle', () => {
    const actor = 'actor';
    const d = (approve: boolean, reason = '') => ({ now, actor, approve, reason });
    expect(decided(missingItem('nid'), d(true))).toBe(VerificationReasons.NotPending);
    const exp = new Date(now.getTime() + HOUR);
    const pending = submitted(missingItem('nid'), now, { issueDate: '2026-06-01' }, exp);
    const approved = decided(pending, d(true)) as Item;
    expect(approved).toMatchObject({ status: 'approved', decidedBy: actor });
    expect(decided(approved, d(true))).toBe(VerificationReasons.NotPending);
    const rejected = decided(approved, d(false, 'fake')) as Item;
    expect(rejected).toMatchObject({ status: 'rejected', reason: 'fake' });
    expect(decided(rejected, d(false, 'again'))).toBe(VerificationReasons.NotPending);
    const again = decided(submitted(rejected, now, {}, exp), d(true)) as Item;
    expect([hasExpired(again, now), hasExpired(again, exp)]).toEqual([false, true]);
    expect(hasExpired({ ...missingItem('x'), status: 'approved' }, now)).toBe(false);
  });

  it('checks the clearance date and NID formats', () => {
    const year = 365 * DAY;
    const sixMonths = new Date('2026-04-09T10:00:00Z');
    expect(clearanceExpiry(sixMonths, now, year)?.getTime()).toBeGreaterThan(now.getTime());
    for (const issued of [new Date(now.getTime() - year), new Date(now.getTime() + DAY)]) {
      expect(clearanceExpiry(issued, now, year)).toBeUndefined();
    }
    const nids = { '1234567890': true, '1234567890123': true, '12345678901234567': true };
    for (const [n, ok] of Object.entries({ ...nids, '123456789': false, '123456789x': false })) {
      expect(validNid(n)).toBe(ok);
    }
    expect(dhakaDate(new Date('2026-10-11T20:00:00Z'))).toEqual(new Date('2026-10-12T00:00:00Z'));
  });

  it('records sessions and the cooling-off period', () => {
    const s: Session = {
      id: 's',
      providerId: 'p',
      serviceId: 'svc',
      scheduledAt: now,
      location: 'Office',
      status: 'scheduled',
      result: '',
      checklist: [],
      notes: '',
      visitLat: null,
      visitLng: null,
      photos: [],
      decidedBy: null,
      decidedAt: null,
      createdAt: now,
    };
    const o = { checklist: [], notes: '', visitLat: null, visitLng: null, photos: [] };
    expect(recorded(s, now, 'a', { ...o, result: 'maybe' })).toBe(VerificationReasons.Invalid);
    const failed = recorded(s, now, 'a', { ...o, result: 'fail' }) as Session;
    expect(failed.status).toBe('completed');
    expect(recorded(failed, now, 'a', { ...o, result: 'pass' })).toBe(
      VerificationReasons.SessionClosed,
    );
    const older = { ...failed, decidedAt: new Date(now.getTime() - 48 * HOUR) };
    const passed = { ...failed, result: 'pass' };
    const sessions = [failed, older, passed];
    expect(retryAfter(sessions, 14 * DAY, now)).toEqual(new Date(now.getTime() + 14 * DAY));
    expect(retryAfter(sessions, HOUR, new Date(now.getTime() + 2 * HOUR))).toBeNull();
    expect(retryAfter([], HOUR, now)).toBeNull();
  });

  it('keeps the state and its level', () => {
    const st = newState('p');
    expect(itemOf(st, 'nid').status).toBe('missing');
    expect(canReceiveBookings(st, 0)).toBe(false);
    st.items = approvedAll();
    expect(recalc(st)).toBe(0);
    expect(canReceiveBookings(st, 1)).toBe(true);
    expect(canReceiveBookings(st, 2)).toBe(false);
    expect(recalc(st)).toBeUndefined();
    st.blocked = true;
    expect(canReceiveBookings(st, 0)).toBe(false);
  });
});
