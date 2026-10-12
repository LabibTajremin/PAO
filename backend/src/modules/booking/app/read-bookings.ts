import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type Booking } from '../domain/booking';
import { BookingReasons } from '../domain/reasons';
import { PAST, Status, UPCOMING } from '../domain/states';
import { REVIEWS, type Reviews } from '../port/peers';
import { type Filter, type Page, type Summary } from '../port/repository';
import { BookingAccess, type Side } from './access';

/** A list tab of the apps. */
export type Tab = 'requests' | 'upcoming' | 'jobs' | 'past' | 'all';

// Providers see open requests on their own tab; their upcoming tab holds accepted jobs.
const TABS: Readonly<Record<Tab, readonly string[]>> = {
  requests: [Status.Requested],
  upcoming: UPCOMING,
  jobs: UPCOMING.filter((s) => s !== Status.Requested),
  past: PAST,
  all: [...UPCOMING, ...PAST],
};

const THIRTY_DAYS_MS = 30 * 86_400_000;
const CODE_STATES: readonly string[] = [Status.Accepted, Status.OnTheWay, Status.Arrived];

/** Booking details, lists and counters for the apps, admins and other modules. */
@Injectable()
export class ReadBookings {
  constructor(
    private readonly access: BookingAccess,
    @Inject(REVIEWS) private readonly reviews: Reviews,
  ) {}

  /**
   * A booking for one side, with whether the caller already reviewed it, so the apps
   * stop offering the review (C-11, P-09) once it is given.
   */
  async detail(party: string, id: string, side: Side) {
    const booking = await this.access.owned(id, party, side);
    return { booking, reviewed: await this.reviewedBy(booking, party) };
  }

  /**
   * Only completed bookings can be reviewed, so other states answer without asking the
   * rating module.
   */
  async reviewedBy(b: Booking, party: string): Promise<boolean> {
    return b.status === Status.Completed && this.reviews.hasReviewed(b.id, party);
  }

  /** The code the customer reads to the provider, from acceptance until the job starts. */
  async startCode(customer: string, id: string): Promise<string> {
    const b = await this.access.owned(id, customer, 'customer');
    if (!CODE_STATES.includes(b.status)) {
      throw new DomainError(BookingReasons.InvalidTransition);
    }
    return b.startCode;
  }

  /** A completed booking for its receipt. */
  async receipt(party: string, id: string): Promise<Booking> {
    const b = await this.access.owned(id, party);
    if (b.status !== Status.Completed) {
      throw new DomainError(BookingReasons.InvalidTransition);
    }
    return b;
  }

  /** A party's bookings on a tab, newest first. */
  list(party: string, side: Side, tab: Tab, p: Page): Promise<Summary[]> {
    const asProvider = side === 'provider';
    const shown = asProvider && tab === 'upcoming' ? 'jobs' : tab;
    return this.access.repo.list({ id: party, asProvider }, TABS[shown], p);
  }

  /** Any booking (admins and other modules). */
  get(id: string): Promise<Booking> {
    return this.access.repo.get(id);
  }

  /** The admin bookings monitor (A-06). */
  monitor(f: Filter, p: Page): Promise<Summary[]> {
    return this.access.repo.monitor(f, p);
  }

  /** Completed jobs and provider cancellations after acceptance in 30 days. */
  stats(provider: string) {
    const since = new Date(this.access.clock.now().getTime() - THIRTY_DAYS_MS);
    return this.access.repo.stats(provider, since);
  }

  /** The provider's active jobs. */
  countActive(provider: string): Promise<number> {
    return this.access.repo.countActive(provider);
  }
}
