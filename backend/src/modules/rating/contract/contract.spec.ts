import { RATING_SERVICE, RatingEvents } from './index';

describe('rating contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(RatingEvents).toEqual({ ReviewSubmitted: 'rating.ReviewSubmitted' });
  });

  it('names its injection token after the service', () => {
    expect(RATING_SERVICE.description).toBe('RatingService');
  });
});
