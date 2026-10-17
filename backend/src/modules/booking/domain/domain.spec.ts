import { type Booking, cancellable, contactsShared, newLine, pending, total } from './booking';
import { days, dhakaDay, isoDate, period } from './earnings';
import { BookingReasons as R } from './reasons';
import { Actor, canTransition, Status } from './states';
import {
  accept,
  advance,
  cancel,
  complete,
  decide,
  propose,
  reject,
  start,
  timeOut,
} from './transitions';

const now = new Date('2026-10-09T10:00:00Z');
const later = (ms: number) => ({ now: new Date(now.getTime() + ms), id: 'e' });
const at = later(0);
const MINUTE = 60_000;
const limits = { maxAttempts: 5, lockoutMs: 10 * MINUTE };
const states = Object.values(Status);

/** A booking in `status` with a deadline three minutes away and code 4821. */
function booking(status: Status, extra: Partial<Booking> = {}): Booking {
  return {
    id: 'b',
    number: 1,
    customer: { id: 'c', name: 'Nusrat', phone: '01812345602' },
    provider: { id: 'p', name: 'Rahim', phone: '01712345601' },
    serviceId: 's',
    serviceName: { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' },
    serviceModel: 'on_demand',
    address: {
      id: 'a',
      area: 'Banani',
      line1: 'House 12',
      line2: '',
      location: { lat: 1, lng: 2 },
    },
    note: '',
    status,
    scheduled: false,
    scheduledAt: null,
    endsAt: null,
    acceptDeadline: new Date(now.getTime() + 3 * MINUTE),
    totalPaisa: 0,
    startCode: '4821',
    codeAttempts: 0,
    codeLockedUntil: null,
    cashReceived: false,
    idempotencyKey: 'k',
    cancelReason: '',
    cancelledBy: '',
    rejectReason: '',
    createdAt: now,
    acceptedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
    lines: [],
    proposals: [],
    timeline: [],
    providerActiveJobs: 0,
    newEvents: [],
    ...extra,
  };
}

const fan = newLine(
  {
    id: 'l1',
    subServiceId: 'fan',
    priceVersionId: 'v',
    name: { en: 'Fan', bn: 'ফ্যান' },
    unit: 'unit',
    unitPaisa: 50000,
    maxQuantity: 10,
  },
  2,
);
if (fan === undefined) {
  throw new Error('fan line');
}

describe('booking state machine', () => {
  it('allows exactly the transitions of docs/booking-states.md', () => {
    const allowed = new Set([
      'requested accepted provider',
      'requested rejected provider',
      'requested timed_out system',
      'requested cancelled customer',
      'accepted on_the_way provider',
      'on_the_way arrived provider',
      'arrived in_progress provider',
      'in_progress completed provider',
      'accepted cancelled customer',
      'on_the_way cancelled customer',
      'arrived cancelled customer',
      'accepted cancelled provider',
      'on_the_way cancelled provider',
      'arrived cancelled provider',
    ]);
    for (const from of states) {
      for (const to of states) {
        for (const actor of Object.values(Actor)) {
          const key = `${from} ${to} ${actor}`;
          expect(`${key} ${String(canTransition(from, to, actor))}`).toBe(
            `${key} ${String(allowed.has(key))}`,
          );
        }
      }
    }
  });

  it('accepts, rejects and times out (TestAcceptRejectTimeout)', () => {
    expect(accept(booking('requested'), later(3 * MINUTE))).toBe(R.DeadlinePassed);
    const busy = booking('requested', { providerActiveJobs: 1 });
    expect(accept(busy, at)).toBe(R.ActiveJob);
    const scheduled = booking('requested', { scheduled: true, providerActiveJobs: 1 });
    expect(accept(scheduled, at)).toBeUndefined();
    expect(scheduled.acceptedAt).toEqual(now);
    expect(scheduled.newEvents).toHaveLength(1);
    expect(accept(scheduled, at)).toBe(R.InvalidTransition);
    expect(reject(booking('requested'), later(60 * MINUTE), 'busy')).toBe(R.DeadlinePassed);
    const b = booking('requested');
    expect(reject(b, at, 'busy')).toBeUndefined();
    expect(b.rejectReason).toBe('busy');
    expect(reject(booking('accepted'), at, 'busy')).toBe(R.InvalidTransition);
    expect(timeOut(booking('requested'), at)).toBe(R.InvalidTransition);
    expect(timeOut(booking('requested'), later(3 * MINUTE))).toBeUndefined();
  });

  it('cancels until the job starts (TestCancel)', () => {
    for (const s of ['in_progress', 'completed'] as const) {
      expect(cancel(booking(s), at, Actor.Customer, 'x')).toBe(R.CancelNotAllowed);
    }
    expect(cancel(booking('requested'), at, Actor.Provider, 'x')).toBe(R.InvalidTransition);
    const b = booking('accepted', { acceptedAt: now });
    expect(cancellable(b)).toBe(true);
    expect(cancel(b, at, Actor.Provider, 'emergency')).toBeUndefined();
    expect(b).toMatchObject({ cancelledBy: 'provider', status: 'cancelled' });
    expect(cancellable(b)).toBe(false);
  });

  it('locks the start code after five wrong tries (TestStartCode)', () => {
    expect(start(booking('on_the_way'), '4821', at, limits)).toBe(R.InvalidTransition);
    const b = booking('arrived');
    for (let i = 0; i < 5; i++) {
      expect(start(b, '0000', at, limits)).toBe(R.CodeWrong);
    }
    expect(b.codeLockedUntil).not.toBeNull();
    expect(b.codeAttempts).toBe(0);
    expect(start(b, '4821', later(9 * MINUTE), limits)).toBe(R.CodeLocked);
    expect(start(b, '4821', later(10 * MINUTE), limits)).toBeUndefined();
    expect(b).toMatchObject({ status: 'in_progress', codeLockedUntil: null });
  });

  it('proposes, decides and completes (TestExtrasAndComplete)', () => {
    const price = { id: 'x', subServiceId: 's', priceVersionId: 'v', name: fan.name, unit: 'unit' };
    expect(newLine({ ...price, unitPaisa: 1, maxQuantity: 10 }, 11)).toBeUndefined();
    expect(newLine({ ...price, unitPaisa: 1, maxQuantity: 0 }, 0)).toBeUndefined();
    const b = booking('arrived', { lines: [fan], totalPaisa: fan.totalPaisa });
    const proposal = (id: string, lines = [fan]) => ({
      id,
      status: 'pending' as const,
      addedPaisa: 0,
      proposedAt: now,
      decidedAt: null,
      lines,
    });
    expect(propose(b, proposal('p1'))).toBe(R.InvalidTransition);
    b.status = 'in_progress';
    expect(propose(b, proposal('p1', []))).toBe(R.Invalid);
    expect(propose(b, proposal('p1'))).toBeUndefined();
    expect(pending(b)?.addedPaisa).toBe(100000);
    expect(propose(b, proposal('p2'))).toBe(R.ExtrasPending);
    expect(complete(b, true, at)).toBe(R.ExtrasPending);
    expect(decide(b, 'other', true, now)).toBe(R.NoProposal);
    expect(decide(b, 'p1', true, now)).toBeUndefined();
    expect(b.totalPaisa).toBe(200000);
    expect(b.lines[1]).toMatchObject({ extra: true, proposalId: 'p1' });
    propose(b, proposal('p3'));
    expect(decide(b, 'p3', false, now)).toBeUndefined();
    expect(b.proposals[1]?.status).toBe('declined');
    expect(b.totalPaisa).toBe(200000);
    expect(complete(b, false, at)).toBe(R.CashNotConfirmed);
    expect(complete(b, true, at)).toBeUndefined();
    expect(b).toMatchObject({ cashReceived: true, completedAt: now });
    expect(advance(booking('accepted'), 'in_progress', at)).toBe(R.InvalidTransition);
    expect(complete(booking('accepted'), true, at)).toBe(R.InvalidTransition);
    expect(advance(booking('accepted'), 'on_the_way', at)).toBeUndefined();
  });

  it('totals nothing and shares contacts only after acceptance (TestTotalsAndPending)', () => {
    expect(pending(booking('in_progress'))).toBeUndefined();
    expect(total([])).toBe(0);
    expect(contactsShared(booking('accepted'))).toBe(false);
    expect(contactsShared(booking('completed', { acceptedAt: now }))).toBe(true);
    expect(contactsShared(booking('cancelled', { acceptedAt: now }))).toBe(false);
  });
});

describe('earnings periods (TestPeriods)', () => {
  const thu = new Date('2026-10-08T00:00:00Z');

  it('finds days, Saturday weeks and months', () => {
    expect(period('day', thu)).toEqual({ from: thu, to: thu });
    const week = period('week', thu);
    expect(week && [isoDate(week.from), isoDate(week.to)]).toEqual(['2026-10-03', '2026-10-09']);
    expect(week && days(week.from, week.to)).toHaveLength(7);
    expect(period('week', new Date('2026-10-03T00:00:00Z'))?.from).toEqual(week?.from);
    const feb = period('month', new Date('2026-02-14T00:00:00Z'));
    expect(feb && [isoDate(feb.from), isoDate(feb.to)]).toEqual(['2026-02-01', '2026-02-28']);
    expect(period('year', thu)).toBeUndefined();
  });

  it('reads the Dhaka date of an instant', () => {
    expect(isoDate(dhakaDay(new Date('2026-10-08T18:30:00Z')))).toBe('2026-10-09');
    expect(isoDate(dhakaDay(new Date('2026-10-08T17:59:00Z')))).toBe('2026-10-08');
  });
});
