import { DomainError, isDomainError } from './domain-error';

describe('DomainError', () => {
  it('carries a reason and its cause', () => {
    const cause = new Error('db');
    const err = new DomainError('booking.not_found', { cause });
    expect(err.name).toBe('DomainError');
    expect(err.message).toBe('booking.not_found');
    expect(err.cause).toBe(cause);
    expect(isDomainError(err, 'booking.not_found')).toBe(true);
    expect(isDomainError(err, 'booking.other')).toBe(false);
    expect(isDomainError(new Error('booking.not_found'), 'booking.not_found')).toBe(false);
  });
});
