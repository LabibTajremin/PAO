import { Injectable } from '@nestjs/common';
import { type Envelope, type EventBus } from '../../../../platform/events/event-bus';
import { Payload } from '../../../../platform/events/payload';
import { type Text } from '../../../../platform/i18n/text';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { BookingEvents } from '../../../booking/contract/events';
import { SubmitReview } from '../../app/submit-review';
import { type Reviewable } from '../../domain/review';

const GO_ZERO_TIME = '0001-01-01T00:00:00Z';

/** The bilingual service name of a completed booking; missing parts are empty. */
function serviceName(env: Envelope): Text {
  const v = (env.payload as unknown as { serviceName?: unknown }).serviceName ?? {};
  const name = new Payload({ ...env, payload: v as Envelope['payload'] });
  return { en: name.text('en'), bn: name.text('bn') };
}

/** Reads a BookingCompleted event. */
export function completedBooking(env: Envelope): Reviewable {
  const p = new Payload(env);
  return {
    bookingId: p.id('bookingId'),
    customerId: p.id('customerId'),
    providerId: p.id('providerId'),
    customerName: p.text('customerName'),
    providerName: p.text('providerName'),
    serviceName: serviceName(env),
    // Go decoded a missing time as its zero time; an invalid date would fail forever.
    completedAt: new Date(p.text('at') || GO_ZERO_TIME),
  };
}

/**
 * Opens completed bookings for review. Opening a booking twice is a no-op, so a
 * redelivered event is harmless.
 */
@Injectable()
@WorkerHooksProvider()
export class RatingWorker implements WorkerHooks {
  constructor(private readonly reviews: SubmitReview) {}

  subscribe(bus: EventBus): void {
    bus.subscribe(BookingEvents.BookingCompleted, 'rating', (env) =>
      this.reviews.open(completedBooking(env)),
    );
  }
}
