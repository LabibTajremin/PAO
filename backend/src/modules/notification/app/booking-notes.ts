import { type Payload } from '../../../platform/events/payload';
import { BookingEvents } from '../../booking/contract/events';
import { App } from '../domain/notification';

/** One recipient of a booking event. */
export interface Note {
  readonly to: string;
  readonly app: App;
  readonly template: string;
  readonly extra?: Readonly<Record<string, string>>;
}

const customer = (p: Payload, template: string): Note => ({
  to: p.id('customerId'),
  app: App.Customer,
  template,
});

const provider = (p: Payload, template: string): Note => ({
  to: p.id('providerId'),
  app: App.Partner,
  template,
});

/** Who hears about each booking event, by event name (02-architecture.md §8). */
export const BOOKING_NOTES: Readonly<Record<string, (p: Payload) => Note[]>> = {
  [BookingEvents.BookingRequested]: (p) => [provider(p, 'booking_requested')],
  [BookingEvents.BookingAccepted]: (p) => [customer(p, 'booking_accepted')],
  [BookingEvents.BookingRejected]: (p) => [customer(p, 'booking_rejected')],
  [BookingEvents.BookingTimedOut]: (p) => [
    customer(p, 'booking_timed_out'),
    provider(p, 'request_missed'),
  ],
  [BookingEvents.ProviderOnTheWay]: (p) => [customer(p, 'provider_on_the_way')],
  [BookingEvents.ProviderArrived]: (p) => [customer(p, 'provider_arrived')],
  [BookingEvents.BookingStarted]: (p) => [customer(p, 'booking_started')],
  [BookingEvents.ExtraItemsProposed]: (p) => [
    {
      ...customer(p, 'extras_proposed'),
      extra: { added: String(Math.trunc(p.number('addedPaisa') / 100)) },
    },
  ],
  [BookingEvents.ExtraItemsDecided]: (p) => [
    {
      ...provider(p, 'extras_decided'),
      extra: { decision: p.flag('approved') ? 'approved' : 'declined' },
    },
  ],
  [BookingEvents.BookingCompleted]: (p) => [
    customer(p, 'booking_completed'),
    provider(p, 'booking_completed'),
  ],
  [BookingEvents.BookingCancelled]: (p) =>
    p.text('by') === 'customer'
      ? [provider(p, 'booking_cancelled')]
      : [customer(p, 'booking_cancelled')],
};
