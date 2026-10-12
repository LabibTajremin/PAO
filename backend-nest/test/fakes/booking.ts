// In-memory stand-ins for the booking module's ports, for its unit specs.
import { FakeClock } from '../../src/platform/clock/fake-clock';
import { DomainError } from '../../src/platform/errors/domain-error';
import { type DomainEvent } from '../../src/platform/events/domain-event';
import { UuidV7Generator } from '../../src/platform/ids/id-generator';
import { BookingAccess } from '../../src/modules/booking/app/access';
import { CreateBooking } from '../../src/modules/booking/app/create-booking';
import { ProviderEarnings } from '../../src/modules/booking/app/earnings';
import { Eligibility } from '../../src/modules/booking/app/eligibility';
import { FindNearby } from '../../src/modules/booking/app/find-nearby';
import { Pricing } from '../../src/modules/booking/app/pricing';
import { ProgressJob } from '../../src/modules/booking/app/progress';
import { ReadBookings } from '../../src/modules/booking/app/read-bookings';
import { RespondToRequests } from '../../src/modules/booking/app/respond';
import { type Booking } from '../../src/modules/booking/domain/booking';
import { BookingReasons } from '../../src/modules/booking/domain/reasons';
import type * as port from '../../src/modules/booking/port/peers';
import {
  type BookingRepository,
  type Change,
  type DayTotal,
  type Page,
  type Summary,
} from '../../src/modules/booking/port/repository';

/** An error the fakes throw on demand. */
export const boom = new Error('boom');

/** Keeps bookings in a map and records what was asked. */
export class MemoryBookings implements BookingRepository {
  readonly rows = new Map<string, Booking>();
  readonly events: DomainEvent[] = [];
  dueIds: string[] = [];
  days: DayTotal[] = [];
  asked: unknown[] = [];

  create(b: Booking, event: (b: Booking) => DomainEvent) {
    const stored = [...this.rows.values()].find((r) => r.idempotencyKey === b.idempotencyKey);
    if (stored) {
      return Promise.resolve({ booking: stored, created: false });
    }
    b.number = this.rows.size + 1;
    this.rows.set(b.id, b);
    this.events.push(event(b));
    return Promise.resolve({ booking: b, created: true });
  }

  get(id: string): Promise<Booking> {
    const b = this.rows.get(id);
    return b
      ? Promise.resolve(structuredClone(b))
      : Promise.reject(new DomainError(BookingReasons.NotFound));
  }

  async change(id: string, fn: Change): Promise<Booking> {
    const b = await this.get(id);
    b.newEvents.length = 0;
    const events = await fn(b);
    this.rows.set(id, b);
    this.events.push(...events);
    return b;
  }

  list(party: { id: string; asProvider: boolean }, statuses: readonly string[], p: Page) {
    this.asked.push({ party, statuses, p });
    return Promise.resolve([] as Summary[]);
  }

  monitor(f: unknown, p: Page) {
    this.asked.push({ f, p });
    return Promise.resolve([] as Summary[]);
  }

  due(): Promise<string[]> {
    return Promise.resolve(this.dueIds);
  }

  earningsByDay(providerId: string, r: unknown) {
    this.asked.push({ providerId, r });
    return Promise.resolve(this.days);
  }

  earningsJobs(providerId: string, r: unknown, p: Page) {
    this.asked.push({ providerId, r, p });
    return Promise.resolve([]);
  }

  stats(providerId: string, since: Date) {
    this.asked.push({ providerId, since });
    return Promise.resolve({ completed: 2, cancellations: 1 });
  }

  countActive(): Promise<number> {
    return Promise.resolve(1);
  }
}

const text = (en: string) => ({ en, bn: en });

/** The peers a booking talks to, with fields specs flip. */
export class FakePeers {
  service: port.Service = {
    id: 'svc',
    name: text('Electrician'),
    model: 'on_demand',
    searchRadiusM: 5000,
    womenProvidersOnly: false,
    published: true,
  };
  prices = new Map<string, port.Price>([
    ['fan', price('fan', 50000, 'unit')],
    ['socket', price('socket', 35000, 'unit')],
    ['day', price('day', 300000, 'day')],
    ['hour', price('hour', 50000, 'hour')],
  ]);
  serviceIds = ['svc'];
  covered = true;
  available = true;
  canReceive = true;
  reviewed = true;
  nearby: port.Nearby[] = [];
  photoFails = false;

  readonly catalog: port.Catalog = {
    service: () => Promise.resolve(this.service),
    price: (id) => {
      const p = this.prices.get(id);
      return p ? Promise.resolve(p) : Promise.reject(new DomainError(BookingReasons.Invalid));
    },
  };
  readonly customers: port.Customers = {
    customer: async (_id, addressId) => ({
      name: 'Nusrat',
      phone: '01812345602',
      address: await this.customers.address('c', addressId),
    }),
    address: (_id, addressId) =>
      Promise.resolve({
        id: addressId,
        area: 'Banani',
        line1: 'House 12',
        line2: '',
        location: { lat: 23.79, lng: 90.4 },
      }),
    covered: () => Promise.resolve(this.covered),
  };
  readonly providers: port.Providers = {
    provider: () =>
      Promise.resolve({ name: 'Rahim', phone: '01712345601', serviceIds: this.serviceIds }),
    isAvailable: () => Promise.resolve(this.available),
    canReceiveBookings: () => Promise.resolve(this.canReceive),
  };
  readonly finder: port.Finder = { findNearby: () => Promise.resolve(this.nearby) };
  readonly media: port.Media = {
    url: (_viewer, id) =>
      this.photoFails ? Promise.reject(boom) : Promise.resolve(`https://media/${id}`),
  };
  readonly settings: port.Settings = {
    rules: () =>
      Promise.resolve({
        acceptAsapMs: 180_000,
        acceptScheduledMs: 3_600_000,
        startCodeMaxAttempts: 5,
        startCodeLockoutMs: 600_000,
      }),
  };
  readonly reviews: port.Reviews = { hasReviewed: () => Promise.resolve(this.reviewed) };
  readonly codes: port.StartCodes = { next: () => '4821' };
}

function price(id: string, amountPaisa: number, unit: string): port.Price {
  return {
    subServiceId: id,
    serviceId: 'svc',
    priceVersionId: `v-${id}`,
    name: text(id),
    unit,
    amountPaisa,
    maxQuantity: 10,
    published: true,
  };
}

/** Every booking use case over the fakes. */
export function bookingFixture() {
  const repo = new MemoryBookings();
  const peers = new FakePeers();
  const clock = new FakeClock(new Date('2026-10-08T06:00:00Z'));
  const ids = new UuidV7Generator();
  const access = new BookingAccess(repo, clock, ids);
  const pricing = new Pricing(peers.catalog, peers.customers, ids);
  const eligibility = new Eligibility(pricing, peers.customers, peers.providers);
  return {
    repo,
    peers,
    clock,
    create: new CreateBooking(access, pricing, eligibility, peers.settings),
    respond: new RespondToRequests(access, peers.codes),
    progress: new ProgressJob(access, pricing, peers.settings),
    reads: new ReadBookings(access, peers.reviews),
    earnings: new ProviderEarnings(access),
    nearby: new FindNearby(pricing, peers.customers, peers.finder, peers.media),
  };
}
