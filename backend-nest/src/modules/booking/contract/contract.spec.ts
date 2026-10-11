import { BOOKING_SERVICE, BookingErrors, BookingEvents, BookingStatus } from './index';

describe('booking contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(BookingEvents).toEqual({
      BookingRequested: 'booking.BookingRequested',
      BookingAccepted: 'booking.BookingAccepted',
      BookingRejected: 'booking.BookingRejected',
      BookingTimedOut: 'booking.BookingTimedOut',
      ProviderOnTheWay: 'booking.ProviderOnTheWay',
      ProviderArrived: 'booking.ProviderArrived',
      BookingStarted: 'booking.BookingStarted',
      ExtraItemsProposed: 'booking.ExtraItemsProposed',
      ExtraItemsDecided: 'booking.ExtraItemsDecided',
      BookingCompleted: 'booking.BookingCompleted',
      BookingCancelled: 'booking.BookingCancelled',
    });
  });

  it('scopes every error reason to booking', () => {
    const reasons = Object.values(BookingErrors);
    expect(reasons.every((r) => r.startsWith('booking.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('matches the states of docs/booking-states.md', () => {
    expect(Object.values(BookingStatus)).toEqual([
      'requested',
      'accepted',
      'on_the_way',
      'arrived',
      'in_progress',
      'completed',
      'rejected',
      'timed_out',
      'cancelled',
    ]);
  });

  it('names its injection token after the service', () => {
    expect(BOOKING_SERVICE.description).toBe('BookingService');
  });
});
