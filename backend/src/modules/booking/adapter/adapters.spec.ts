import { bookingErrors } from './http/error-map';
import { badge } from './http/discovery.controller';
import { lineView } from './http/views';
import { BOOKING_OUTBOX } from './postgres/booking-repository';
import { RandomStartCodes } from './peers/peers';

describe('booking adapters', () => {
  it('badges search results by level (TestBadge)', () => {
    expect([badge(1), badge(2)]).toEqual(['verified', 'verified_pro']);
  });

  it('maps every booking reason to an API error', () => {
    expect(Object.keys(bookingErrors)).toHaveLength(15);
    expect(BOOKING_OUTBOX.description).toBe('BookingOutbox');
  });

  it('shows a line with its prices', () => {
    const line = {
      id: 'l',
      subServiceId: 's',
      priceVersionId: 'v',
      name: { en: 'Fan', bn: 'ফ্যান' },
      unit: 'unit',
      quantity: 2,
      unitPaisa: 50000,
      totalPaisa: 100000,
      extra: false,
      proposalId: null,
      position: 0,
    };
    expect(lineView(line)).toMatchObject({ unitPrice: 50000, total: 100000, extra: false });
  });

  it('makes four-digit start codes', () => {
    expect(new RandomStartCodes().next()).toMatch(/^\d{4}$/);
  });
});
