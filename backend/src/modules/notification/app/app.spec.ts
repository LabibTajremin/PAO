import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { EventBus } from '../../../platform/events/event-bus';
import { SequenceIdGenerator } from '../../../platform/ids/id-generator';
import { discardLogger } from '../../../platform/logging/logger';
import { NotificationContract } from '../adapter/inproc/notification-contract';
import { NotificationWorker } from '../adapter/inproc/worker-hooks';
import {
  type App,
  type Notification,
  NotificationReasons,
  type Push,
} from '../domain/notification';
import {
  type BookingFacts,
  type Device,
  InvalidTokenError,
  type NotificationRepository,
  type Page,
} from '../port/ports';
import { EventNotes } from './event-notes';
import { Inbox } from './inbox';
import { PushDevices } from './push-devices';
import { SendNotification } from './send';

/** Keeps the inbox and devices in memory, like the Postgres repository. */
class FakeRepository implements NotificationRepository {
  items: Notification[] = [];
  devices: Device[] = [];
  failDrop = false;

  add(n: Notification): Promise<boolean> {
    const seen = this.items.some(
      (i) => i.recipientId === n.recipientId && i.dedupeKey === n.dedupeKey,
    );
    if (!seen) {
      this.items.push(n);
    }
    return Promise.resolve(!seen);
  }

  list(recipient: string, app: App, page: Page): Promise<Notification[]> {
    const mine = this.items.filter((i) => i.recipientId === recipient && i.app === app);
    return Promise.resolve(mine.reverse().slice(0, page.limit));
  }

  async unread(recipient: string, app: App): Promise<number> {
    return (await this.list(recipient, app, { limit: 1000 })).filter((i) => !i.read).length;
  }

  markRead(recipient: string, app: App, id: string): Promise<void> {
    const i = this.items.findIndex(
      (n) => n.id === id && n.recipientId === recipient && n.app === app,
    );
    if (i < 0) {
      return Promise.reject(new DomainError(NotificationReasons.NotFound));
    }
    this.items[i] = { ...this.items[i]!, read: true };
    return Promise.resolve();
  }

  markAllRead(recipient: string, app: App): Promise<void> {
    this.items = this.items.map((n) =>
      n.recipientId === recipient && n.app === app ? { ...n, read: true } : n,
    );
    return Promise.resolve();
  }

  saveDevice(d: Device): Promise<void> {
    this.devices = [...this.devices.filter((x) => x.token !== d.token), d];
    return Promise.resolve();
  }

  tokens(account: string, app: App): Promise<string[]> {
    return Promise.resolve(
      this.devices.filter((d) => d.accountId === account && d.app === app).map((d) => d.token),
    );
  }

  dropToken(token: string): Promise<void> {
    if (this.failDrop) {
      return Promise.reject(new Error('db down'));
    }
    this.devices = this.devices.filter((d) => d.token !== token);
    return Promise.resolve();
  }

  forget(account: string): Promise<void> {
    this.items = this.items.filter((n) => n.recipientId !== account);
    this.devices = this.devices.filter((d) => d.accountId !== account);
    return Promise.resolve();
  }
}

const facts: BookingFacts = {
  number: 'PAO-100001',
  serviceEn: 'Fan install',
  serviceBn: 'ফ্যান লাগানো',
  area: 'Gulshan',
  providerName: 'Rahim',
  customerName: 'Nusrat',
};

function setup() {
  const repo = new FakeRepository();
  const pushed: { token: string; push: Push }[] = [];
  const pusher = {
    push: (token: string, push: Push) => {
      if (token.startsWith('invalid-')) {
        return Promise.reject(new InvalidTokenError());
      }
      if (token.startsWith('broken-')) {
        return Promise.reject(new Error('down'));
      }
      pushed.push({ token, push });
      return Promise.resolve();
    },
  };
  const clock = new FakeClock(new Date('2026-10-01T10:00:00Z'));
  const log = discardLogger();
  const sender = new SendNotification(
    repo,
    new PushDevices(repo, pusher, log),
    clock,
    new SequenceIdGenerator([]),
  );
  const inbox = new Inbox(repo, clock);
  const languages = { language: (id: string) => Promise.resolve(id === 'english' ? 'en' : 'bn') };
  const bookings = { booking: (id: string) => Promise.resolve(id === 'b1' ? facts : undefined) };
  const notes = new EventNotes(sender, languages, bookings, log);
  const bus = new EventBus();
  new NotificationWorker(notes, inbox).subscribe(bus);
  let n = 0;
  const deliver = (name: string, payload: Record<string, unknown>) => {
    const env = { id: `e${++n}`, module: 'x', name, aggregateId: '', occurredAt: new Date() };
    return bus.dispatch({ ...env, payload: { name, ...payload } });
  };
  return { repo, pushed, sender, inbox, deliver, contract: new NotificationContract(sender) };
}

const parties = { bookingId: 'b1', customerId: 'cust', providerId: 'english' };
const types = (repo: FakeRepository, to: string) =>
  repo.items.filter((i) => i.recipientId === to).map((i) => i.type);

describe('sending', () => {
  it('stores once, pushes live devices and drops dead ones', async () => {
    const { repo, pushed, inbox, contract } = setup();
    for (const token of ['tok-1', 'invalid-1', 'broken-1']) {
      await inbox.registerDevice({ token, accountId: 'c', app: 'customer', platform: 'android' });
    }
    const m = {
      recipientId: 'c',
      app: 'customer',
      language: 'en' as const,
      template: 'complaint_resolved',
      data: { ticket: '1001' },
      bookingId: null,
      channels: [],
      dedupeKey: 'k1',
    };
    await contract.send(m);
    await contract.send(m);
    expect(repo.items).toHaveLength(1);
    expect(pushed).toEqual([
      {
        token: 'tok-1',
        push: {
          title: 'Report resolved',
          body: 'Your report 1001 has been resolved.',
          data: { type: 'complaint_resolved' },
        },
      },
    ]);
    expect(repo.devices.map((d) => d.token)).toEqual(['tok-1', 'broken-1']);
    repo.failDrop = true;
    await inbox.registerDevice({
      token: 'invalid-2',
      accountId: 'c',
      app: 'customer',
      platform: 'ios',
    });
    await contract.send({ ...m, dedupeKey: 'k2' });
    for (const bad of [{ template: 'nope' }, { dedupeKey: '' }, { app: 'admin' }]) {
      await expect(contract.send({ ...m, ...bad })).rejects.toThrow(NotificationReasons.Invalid);
    }
  });

  it('keeps read state per recipient and app', async () => {
    const { repo, inbox, deliver } = setup();
    await deliver('booking.BookingCompleted', parties);
    const [first] = (await inbox.page('cust', 'customer', { limit: 10 })).items;
    await expect(inbox.markRead('english', 'partner', first!.id)).rejects.toThrow(
      NotificationReasons.NotFound,
    );
    await inbox.markRead('cust', 'customer', first!.id);
    expect((await inbox.page('cust', 'customer', { limit: 10 })).unread).toBe(0);
    await inbox.markAllRead('english', 'partner');
    expect((await inbox.page('english', 'partner', { limit: 10 })).unread).toBe(0);
    await deliver('identity.AccountDeleted', { accountId: 'cust' });
    expect(types(repo, 'cust')).toEqual([]);
    expect(types(repo, 'english')).toEqual(['booking_completed']);
  });
});

describe('event notes', () => {
  it.each([
    ['booking.BookingRequested', {}, [], ['booking_requested']],
    ['booking.BookingAccepted', {}, ['booking_accepted'], []],
    ['booking.BookingRejected', {}, ['booking_rejected'], []],
    ['booking.BookingTimedOut', {}, ['booking_timed_out'], ['request_missed']],
    ['booking.ProviderOnTheWay', {}, ['provider_on_the_way'], []],
    ['booking.ProviderArrived', {}, ['provider_arrived'], []],
    ['booking.BookingStarted', {}, ['booking_started'], []],
    ['booking.ExtraItemsProposed', { addedPaisa: 35050 }, ['extras_proposed'], []],
    ['booking.ExtraItemsDecided', { approved: true }, [], ['extras_decided']],
    ['booking.ExtraItemsDecided', {}, [], ['extras_decided']],
    ['booking.BookingCompleted', {}, ['booking_completed'], ['booking_completed']],
    ['booking.BookingCancelled', { by: 'customer' }, [], ['booking_cancelled']],
    ['booking.BookingCancelled', { by: 'provider' }, ['booking_cancelled'], []],
  ])('%s %j reaches the right sides', async (name, extra, customer, provider) => {
    const { repo, deliver } = setup();
    await deliver(name, { ...parties, ...extra });
    await deliver(name, { ...parties, ...extra, bookingId: 'unknown' });
    expect(types(repo, 'cust')).toEqual(customer);
    expect(types(repo, 'english')).toEqual(provider);
  });

  it('writes each side in its own language with the booking details', async () => {
    const { repo, deliver } = setup();
    await deliver('booking.BookingRequested', parties);
    await deliver('booking.ExtraItemsProposed', { ...parties, addedPaisa: 35050 });
    await deliver('booking.ExtraItemsDecided', { ...parties, approved: true });
    expect(repo.items.map((i) => i.body)).toEqual([
      'Fan install in Gulshan — answer before the time runs out.',
      'আপনার সেবাদাতা ৳350 মূল্যের আইটেম যোগ করেছেন। অনুমোদন বা বাতিল করুন।',
      'The customer approved the extra items on booking PAO-100001.',
    ]);
    expect(repo.items[0]?.bookingId).toBe('b1');
  });

  it('tells providers about verification in their language', async () => {
    const { repo, deliver } = setup();
    const events: [string, Record<string, unknown>][] = [
      ['verification.ProviderLevelChanged', { from: 0, to: 1 }],
      ['verification.DocumentRejected', { item: 'selfie', reason: 'Blurred' }],
      ['verification.DocumentExpired', { item: 'police_clearance' }],
      ['verification.DocumentExpiring', { item: 'unknown_item', daysLeft: 7 }],
      [
        'verification.Level2SessionScheduled',
        { scheduledAt: '2026-10-12T10:00:00Z', location: 'Gulshan' },
      ],
    ];
    for (const [name, payload] of events) {
      await deliver(name, { providerId: 'english', ...payload });
    }
    await deliver('verification.DocumentRejected', {
      providerId: 'bangla',
      item: 'selfie',
      reason: 'x',
    });
    expect(repo.items.map((i) => i.body)).toEqual([
      'Your verification level is now 1.',
      'Your selfie was not approved: Blurred',
      'Your police clearance has expired. Renew it to receive bookings again.',
      'Your  expires in 7 days.',
      'Your Level 2 session is at Gulshan on 2026-10-12T10:00:00Z.',
      'আপনার সেলফি অনুমোদিত হয়নি: x',
    ]);
  });

  it('tells the reporter a complaint is resolved', async () => {
    const { repo, deliver } = setup();
    await deliver('admin.ComplaintResolved', {
      reporterId: 'cust',
      reporterRole: 'customer',
      ticketNumber: 'T-1',
    });
    await deliver('admin.ComplaintResolved', {
      reporterId: 'english',
      reporterRole: 'provider',
      ticketNumber: 'T-2',
    });
    expect(repo.items.map((i) => [i.app, i.body])).toEqual([
      ['customer', 'আপনার অভিযোগ T-1-এর সমাধান হয়েছে।'],
      ['partner', 'Your report T-2 has been resolved.'],
    ]);
    await expect(
      deliver('admin.ComplaintResolved', { reporterId: 'x', reporterRole: 'admin' }),
    ).rejects.toThrow();
  });

  it('fails on a payload that is not an object', async () => {
    const { deliver } = setup();
    await expect(deliver('booking.BookingAccepted', { bookingId: 5 })).rejects.toThrow();
  });
});
