import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { SequenceIdGenerator } from '../../../platform/ids/id-generator';
import { EventBus } from '../../../platform/events/event-bus';
import { BookingEvents } from '../../booking/contract/events';
import { completedBooking, RatingWorker } from '../adapter/inproc/worker-hooks';
import { RatingContract } from '../adapter/inproc/rating-contract';
import { type Aggregate } from '../domain/aggregate';
import { RatingReasons, type Review, type Reviewable, ReviewRole } from '../domain/review';
import { type Page, type RatingRepository } from '../port/repository';
import { Ratings } from './ratings';
import { SubmitReview } from './submit-review';

/** Keeps everything in memory, like the Postgres repository. */
class FakeRepository implements RatingRepository {
  readonly bookings = new Map<string, Reviewable>();
  readonly stored: Review[] = [];
  readonly events: DomainEvent[] = [];
  readonly sums = new Map<string, Aggregate>();

  addReviewable(b: Reviewable): Promise<void> {
    this.bookings.set(b.bookingId, this.bookings.get(b.bookingId) ?? b);
    return Promise.resolve();
  }

  reviewable(id: string): Promise<Reviewable> {
    const b = this.bookings.get(id);
    return b ? Promise.resolve(b) : Promise.reject(new DomainError(RatingReasons.NotAllowed));
  }

  submit(r: Review, event: (a: Aggregate) => DomainEvent): Promise<Aggregate> {
    if (this.stored.some((s) => s.bookingId === r.bookingId && s.authorId === r.authorId)) {
      return Promise.reject(new DomainError(RatingReasons.AlreadyReviewed));
    }
    this.stored.push(r);
    const key = r.subjectId;
    const old = this.sums.get(key) ?? { count: 0, sum: 0, distribution: [0, 0, 0, 0, 0] };
    const distribution = [...old.distribution] as [number, number, number, number, number];
    distribution[r.stars - 1] = (distribution[r.stars - 1] ?? 0) + 1;
    const a = { count: old.count + 1, sum: old.sum + r.stars, distribution };
    this.sums.set(key, a);
    this.events.push(event(a));
    return Promise.resolve(a);
  }

  aggregates(_role: ReviewRole, ids: readonly string[]): Promise<Map<string, Aggregate>> {
    const found = ids.flatMap((id) => {
      const a = this.sums.get(id);
      return a ? [[id, a] as const] : [];
    });
    return Promise.resolve(new Map(found));
  }

  reviews(subject: string, role: ReviewRole, page: Page): Promise<Review[]> {
    const rows = this.stored.filter((r) => r.subjectId === subject && r.authorRole === role);
    return Promise.resolve(rows.reverse().slice(0, page.limit));
  }

  hasReviewed(bookingId: string, authorId: string): Promise<boolean> {
    return Promise.resolve(
      this.stored.some((r) => r.bookingId === bookingId && r.authorId === authorId),
    );
  }
}

const booking: Reviewable = {
  bookingId: 'b1',
  customerId: 'c1',
  providerId: 'p1',
  customerName: 'Nusrat Jahan',
  providerName: 'Rahim Uddin',
  serviceName: { en: 'Fan install', bn: 'ফ্যান' },
  completedAt: new Date('2026-10-01T10:00:00Z'),
};

function setup() {
  const repo = new FakeRepository();
  const clock = new FakeClock(new Date('2026-10-02T10:00:00Z'));
  const submit = new SubmitReview(repo, clock, new SequenceIdGenerator([]));
  const ratings = new Ratings(repo);
  return { repo, submit, ratings, contract: new RatingContract(ratings) };
}

describe('rating use cases', () => {
  it('opens a completed booking from its event, once', async () => {
    const { repo, submit } = setup();
    const bus = new EventBus();
    new RatingWorker(submit).subscribe(bus);
    const event = { name: BookingEvents.BookingCompleted, ...booking, at: '2026-10-01T10:00:00Z' };
    const env = { id: 'e1', module: 'booking', aggregateId: 'b1', occurredAt: new Date() };
    for (const payload of [event, { ...event, customerName: 'Someone Else' }]) {
      await bus.dispatch({ ...env, name: event.name, payload });
    }
    expect(repo.bookings.get('b1')).toEqual(booking);
  });

  it('reads missing event fields as empty values', () => {
    const env = { id: 'e', module: 'booking', aggregateId: '', occurredAt: new Date() };
    const b = completedBooking({
      ...env,
      name: 'booking.BookingCompleted',
      payload: { name: 'x' },
    });
    expect(b.serviceName).toEqual({ en: '', bn: '' });
  });

  it('stores each side once and publishes the new aggregate', async () => {
    const { repo, submit, contract } = setup();
    await submit.open(booking);
    const customer = { id: 'c1', role: ReviewRole.Customer };
    const r = await submit.review(customer, 'b1', { stars: 4, tags: ['clean'], comment: '' });
    expect(r).toMatchObject({ subjectId: 'p1', createdAt: new Date('2026-10-02T10:00:00Z') });
    expect(repo.events).toEqual([
      expect.objectContaining({
        name: 'rating.ReviewSubmitted',
        subjectRole: 'provider',
        newAverage: 4,
        newCount: 1,
      }),
    ]);
    await expect(
      submit.review(customer, 'b1', { stars: 4, tags: [], comment: '' }),
    ).rejects.toThrow(RatingReasons.AlreadyReviewed);
    await expect(
      submit.review(customer, 'nope', { stars: 4, tags: [], comment: '' }),
    ).rejects.toThrow(RatingReasons.NotAllowed);
    expect(await contract.hasReviewed('b1', 'c1')).toBe(true);
    expect(await contract.hasReviewed('b1', 'p1')).toBe(false);
  });

  it('answers the contract with zero values for the unrated', async () => {
    const { submit, ratings, contract } = setup();
    await submit.open(booking);
    await submit.review({ id: 'c1', role: ReviewRole.Customer }, 'b1', {
      stars: 4,
      tags: [],
      comment: '',
    });
    await submit.review({ id: 'p1', role: ReviewRole.Provider }, 'b1', {
      stars: 5,
      tags: [],
      comment: '',
    });
    expect(await contract.getProviderRating('p1')).toEqual({
      average: 4,
      count: 1,
      distribution: [0, 0, 0, 1, 0],
    });
    expect(await contract.getCustomerRating('c1')).toMatchObject({ average: 5, count: 1 });
    expect((await contract.getProviderRatings(['p1', 'x'])).size).toBe(1);
    expect(await contract.getProviderRating('x')).toEqual({
      average: 0,
      count: 0,
      distribution: [0, 0, 0, 0, 0],
    });
    expect(await ratings.providerReviews('p1', { limit: 10 })).toHaveLength(1);
  });
});
