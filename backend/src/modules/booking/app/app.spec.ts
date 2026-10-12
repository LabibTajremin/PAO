import { bookingFixture, boom } from '../../../../test/fakes/booking';
import { type Booking } from '../domain/booking';
import { BookingReasons as R } from '../domain/reasons';
import { bookingNumber } from './access';
import { type CreateInput } from './create-booking';

const reason = (r: string) => ({ reason: r });
const input: CreateInput = {
  customerId: 'c',
  providerId: 'p',
  serviceId: 'svc',
  addressId: 'a',
  items: [{ subServiceId: 'fan', quantity: 2 }],
  scheduledAt: null,
  note: '  Second floor ',
  idempotencyKey: 'k1',
};

type Fixture = ReturnType<typeof bookingFixture>;

async function book(f: Fixture, extra: Partial<CreateInput> = {}): Promise<Booking> {
  return (await f.create.execute({ ...input, ...extra })).booking;
}

async function started(f: Fixture): Promise<Booking> {
  const b = await book(f);
  await f.respond.accept('p', b.id);
  await f.progress.advance('p', b.id, 'on_the_way');
  await f.progress.advance('p', b.id, 'arrived');
  return f.progress.start('p', b.id, '4821');
}

describe('create booking', () => {
  it('snapshots the request and replays its key', async () => {
    const f = bookingFixture();
    const b = await book(f);
    expect(b).toMatchObject({ number: 1, note: 'Second floor', totalPaisa: 100000, endsAt: null });
    expect(bookingNumber(b.number)).toBe('PAO-1');
    expect(f.repo.events[0]).toMatchObject({
      name: 'booking.BookingRequested',
      totalPaisa: 100000,
    });
    expect((await f.create.execute(input)).created).toBe(false);
  });

  it('times duration hires by hours and days, from the scheduled start', async () => {
    const f = bookingFixture();
    f.peers.service = { ...f.peers.service, model: 'duration_hire' };
    const day = await book(f, {
      items: [{ subServiceId: 'day', quantity: 2 }],
      idempotencyKey: 'd',
    });
    expect(day.endsAt?.getTime()).toBe(f.clock.now().getTime() + 2 * 86_400_000);
    const at = new Date(f.clock.now().getTime() + 86_400_000);
    const hour = await book(f, {
      items: [{ subServiceId: 'hour', quantity: 3 }],
      scheduledAt: at,
      idempotencyKey: 'h',
    });
    expect(hour.endsAt?.getTime()).toBe(at.getTime() + 3 * 3_600_000);
    expect(hour.acceptDeadline.getTime()).toBe(f.clock.now().getTime() + 3_600_000);
  });

  it('refuses invalid, unbookable and out-of-area requests', async () => {
    const f = bookingFixture();
    const refusals: [Partial<CreateInput>, string][] = [
      [{ idempotencyKey: ' ' }, R.Invalid],
      [{ items: [] }, R.Invalid],
      [{ note: 'x'.repeat(501) }, R.Invalid],
      [{ scheduledAt: f.clock.now() }, R.Invalid],
      [{ items: [{ subServiceId: 'fan', quantity: 11 }] }, R.Invalid],
      [{ items: [{ subServiceId: 'nope', quantity: 1 }] }, R.Invalid],
    ];
    for (const [extra, r] of refusals) {
      await expect(book(f, extra)).rejects.toMatchObject(reason(r));
    }
    const fan = f.peers.prices.get('fan');
    if (fan) {
      f.peers.prices.set('fan', { ...fan, published: false });
    }
    await expect(book(f)).rejects.toMatchObject(reason(R.Invalid));
    const g = bookingFixture();
    for (const flip of [
      () => (g.peers.covered = false),
      () => (g.peers.available = false),
      () => (g.peers.canReceive = false),
      () => (g.peers.serviceIds = []),
      () => (g.peers.service = { ...g.peers.service, model: 'listing' }),
      () => (g.peers.service = { ...g.peers.service, published: false }),
    ]) {
      flip();
      await expect(book(g)).rejects.toHaveProperty('reason');
    }
  });
});

describe('respond and cancel', () => {
  it('accepts with a start code, rejects and cancels by side', async () => {
    const f = bookingFixture();
    const b = await book(f);
    await expect(f.respond.accept('stranger', b.id)).rejects.toMatchObject(reason(R.NotFound));
    expect((await f.respond.accept('p', b.id)).startCode).toBe('4821');
    const other = await book(f, { idempotencyKey: 'k2' });
    expect((await f.respond.reject('p', other.id, 'busy: far')).rejectReason).toBe('busy: far');
    await expect(f.respond.cancel('provider', 'c', b.id, 'x')).rejects.toMatchObject(
      reason(R.NotFound),
    );
    const cancelled = await f.respond.cancel('provider', 'p', b.id, 'emergency');
    expect(cancelled.status).toBe('cancelled');
    expect(f.repo.events.at(-1)).toMatchObject({ by: 'provider', afterAcceptance: true });
    await expect(f.respond.cancel('customer', 'c', b.id, 'x')).rejects.toMatchObject(
      reason(R.InvalidTransition),
    );
  });

  it('times out due requests and skips ones that moved on (TestExpireDue_SkipsBookingsThatMovedOn)', async () => {
    const f = bookingFixture();
    const due = await book(f);
    const moved = await book(f, { idempotencyKey: 'k2' });
    await f.respond.accept('p', moved.id);
    f.clock.advance(3 * 60_000);
    f.repo.dueIds = [due.id, moved.id];
    const before = f.repo.events.length;
    await f.respond.expireDue();
    expect(f.repo.events.slice(before).map((e) => e.name)).toEqual(['booking.BookingTimedOut']);
    expect((await f.reads.get(moved.id)).status).toBe('accepted');
  });
});

describe('progress', () => {
  it('saves wrong codes, proposes extras after the bill and completes', async () => {
    const f = bookingFixture();
    const b = await book(f);
    await f.respond.accept('p', b.id);
    await f.progress.advance('p', b.id, 'on_the_way');
    await f.progress.advance('p', b.id, 'arrived');
    await expect(f.progress.start('p', b.id, '0000')).rejects.toMatchObject(reason(R.CodeWrong));
    expect((await f.reads.get(b.id)).codeAttempts).toBe(1);
    await expect(f.progress.start('p', b.id, '4821')).resolves.toMatchObject({
      status: 'in_progress',
    });
    await expect(f.progress.start('p', b.id, '4821')).rejects.toMatchObject(
      reason(R.InvalidTransition),
    );
    await expect(f.progress.proposeExtras('p', b.id, [])).rejects.toMatchObject(reason(R.Invalid));
    const extra = [{ subServiceId: 'socket', quantity: 1 }];
    const first = await f.progress.proposeExtras('p', b.id, extra);
    const p1 = first.proposals[0]?.id ?? '';
    await f.progress.decideExtras('c', b.id, p1, false);
    const second = await f.progress.proposeExtras('p', b.id, extra);
    expect(second.proposals[1]?.lines[0]?.position).toBe(2);
    expect(f.repo.events.at(-1)).toMatchObject({ addedPaisa: 35000, newTotalPaisa: 135000 });
    const p2 = second.proposals[1]?.id ?? '';
    await expect(f.progress.decideExtras('p', b.id, p2, true)).rejects.toMatchObject(
      reason(R.NotFound),
    );
    expect((await f.progress.decideExtras('c', b.id, p2, true)).totalPaisa).toBe(135000);
    const done = await f.progress.complete('p', b.id, true);
    expect(done.status).toBe('completed');
    expect(f.repo.events.at(-1)).toMatchObject({ customerName: 'Nusrat', providerName: 'Rahim' });
  });
});

describe('reads', () => {
  it('answers details, codes, receipts and lists', async () => {
    const f = bookingFixture();
    const b = await started(f);
    expect(await f.reads.detail('c', b.id, 'customer')).toMatchObject({ reviewed: false });
    await expect(f.reads.detail('c', b.id, 'provider')).rejects.toMatchObject(reason(R.NotFound));
    await expect(f.reads.startCode('c', b.id)).rejects.toMatchObject(reason(R.InvalidTransition));
    await expect(f.reads.receipt('p', b.id)).rejects.toMatchObject(reason(R.InvalidTransition));
    await f.progress.complete('p', b.id, true);
    expect(await f.reads.detail('p', b.id, 'provider')).toMatchObject({ reviewed: true });
    expect(
      (await f.reads.receipt('stranger', b.id).catch((e: unknown) => e)) as object,
    ).toMatchObject(reason(R.NotFound));
    expect((await f.reads.receipt('c', b.id)).status).toBe('completed');
    const accepted = await book(f, { idempotencyKey: 'k2' });
    await f.respond.accept('p', accepted.id);
    expect(await f.reads.startCode('c', accepted.id)).toBe('4821');
    const p = { at: null, id: null, limit: 3 };
    await f.reads.list('p', 'provider', 'upcoming', p);
    await f.reads.list('c', 'customer', 'upcoming', p);
    await f.reads.monitor({ status: null, serviceId: null, from: null, until: null, area: '' }, p);
    expect(f.repo.asked.slice(0, 2)).toEqual([
      {
        party: { id: 'p', asProvider: true },
        statuses: ['accepted', 'on_the_way', 'arrived', 'in_progress'],
        p,
      },
      {
        party: { id: 'c', asProvider: false },
        statuses: ['requested', 'accepted', 'on_the_way', 'arrived', 'in_progress'],
        p,
      },
    ]);
    expect(await f.reads.stats('p')).toEqual({ completed: 2, cancellations: 1 });
    expect(await f.reads.countActive('p')).toBe(1);
  });
});

describe('earnings', () => {
  it('fills every day of the period and defaults to this month', async () => {
    const f = bookingFixture();
    f.repo.days = [{ day: new Date('2026-10-08T00:00:00Z'), total: 5000, jobs: 1 }];
    const week = await f.earnings.summary('p', 'week', null);
    expect(week).toMatchObject({ total: 5000, jobs: 1 });
    expect(week.days).toHaveLength(7);
    const day = await f.earnings.summary('p', 'day', new Date('2026-01-01T00:00:00Z'));
    expect(day.days).toHaveLength(1);
    await expect(f.earnings.summary('p', 'year', null)).rejects.toMatchObject(reason(R.Invalid));
    const p = { at: null, id: null, limit: 2 };
    await f.earnings.jobs('p', { from: null, to: null }, p);
    expect(f.repo.asked.at(-1)).toEqual({
      providerId: 'p',
      r: { from: new Date('2026-09-30T18:00:00Z'), until: new Date('2026-10-31T18:00:00Z') },
      p,
    });
    const from = new Date('2026-01-01T00:00:00Z');
    await f.earnings.jobs('p', { from, to: from }, p);
    expect(f.repo.asked.at(-1)).toMatchObject({
      r: { from: new Date('2025-12-31T18:00:00Z'), until: new Date('2026-01-01T18:00:00Z') },
    });
  });
});

describe('nearby', () => {
  const q = {
    customerId: 'c',
    serviceId: 'svc',
    subServiceId: 'fan',
    quantity: 2,
    addressId: null,
    at: { lat: 23.79, lng: 90.4 },
    byRating: false,
    limit: 20,
  };
  const card = {
    id: 'p',
    name: 'Rahim',
    level: 1,
    rating: 0,
    ratingCount: 0,
    completedJobs: 0,
    distanceM: 10,
  };

  it('prices the job and signs photos it can', async () => {
    const f = bookingFixture();
    f.peers.nearby = [
      { ...card, photoMediaId: 'ph' },
      { ...card, photoMediaId: null },
    ];
    const r = await f.nearby.execute({ ...q, addressId: 'a', at: null });
    expect(r.price.totalPaisa).toBe(100000);
    expect(r.providers.map((c) => c.photoUrl)).toEqual(['https://media/ph', '']);
    f.peers.photoFails = true;
    expect((await f.nearby.execute(q)).providers[0]?.photoUrl).toBe('');
    await expect(f.nearby.execute({ ...q, at: null })).rejects.toMatchObject(reason(R.Invalid));
    f.peers.covered = false;
    await expect(f.nearby.execute(q)).rejects.toMatchObject(reason(R.OutsideArea));
    expect(boom.message).toBe('boom');
  });
});
