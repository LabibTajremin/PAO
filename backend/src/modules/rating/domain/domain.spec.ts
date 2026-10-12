import { average, UNRATED } from './aggregate';
import {
  firstName,
  newReview,
  RatingReasons,
  type Reviewable,
  ReviewRole,
  subjectRole,
} from './review';

const booking: Reviewable = {
  bookingId: 'b1',
  customerId: 'c1',
  providerId: 'p1',
  customerName: 'Nusrat Jahan',
  providerName: 'Rahim Uddin',
  serviceName: { en: 'Fan install', bn: 'ফ্যান' },
  completedAt: new Date(),
};

const customer = { id: 'c1', role: ReviewRole.Customer };
const none = { stars: 5, tags: [], comment: '' };

function ok<T>(r: T | string): T {
  if (typeof r === 'string') {
    throw new Error(r);
  }
  return r;
}

describe('newReview', () => {
  it('lets the customer review the provider under their first name', () => {
    const r = ok(
      newReview(booking, customer, { stars: 5, tags: ['on_time'], comment: '  Great ' }),
    );
    expect(r).toMatchObject({ subjectId: 'p1', authorName: 'Nusrat', comment: 'Great' });
    expect(subjectRole(r.authorRole)).toBe(ReviewRole.Provider);
  });

  it('lets the provider review the customer', () => {
    const r = ok(
      newReview(booking, { id: 'p1', role: ReviewRole.Provider }, { ...none, stars: 4 }),
    );
    expect(r).toMatchObject({ subjectId: 'c1', authorName: 'Rahim', tags: [] });
    expect(subjectRole(r.authorRole)).toBe(ReviewRole.Customer);
  });

  it('refuses strangers and a customer posing as the provider', () => {
    expect(newReview(booking, { ...customer, id: 'x' }, none)).toBe(RatingReasons.NotAllowed);
    expect(newReview(booking, { ...customer, role: ReviewRole.Provider }, none)).toBe(
      RatingReasons.NotAllowed,
    );
  });

  it.each([
    { stars: 0, tags: [], comment: '' },
    { stars: 6, tags: [], comment: '' },
    { stars: 4.5, tags: [], comment: '' },
    { stars: 5, tags: ['a', 'a'], comment: '' },
    { stars: 5, tags: ['a', 'b', 'c', 'd', 'e', 'f', 'g'], comment: '' },
    { stars: 5, tags: [], comment: 'x'.repeat(501) },
  ])('refuses invalid content %#', (input) => {
    expect(newReview(booking, customer, input)).toBe(RatingReasons.Invalid);
  });

  it('counts a comment in characters, not bytes', () => {
    expect(
      ok(newReview(booking, customer, { ...none, comment: 'ক'.repeat(500) })).comment,
    ).toHaveLength(500);
  });

  it('keeps a blank name blank', () => {
    expect(firstName('  ')).toBe('');
  });
});

describe('average', () => {
  it('is zero when unrated and rounded to one decimal otherwise', () => {
    expect(average(UNRATED)).toBe(0);
    expect(average({ count: 3, sum: 14, distribution: [0, 0, 0, 2, 1] })).toBe(4.7);
  });
});
