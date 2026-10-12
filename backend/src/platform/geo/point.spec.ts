import { type Point } from './point';

describe('Point', () => {
  it('is a WGS84 position in decimal degrees', () => {
    const banani: Point = { lat: 23.7937, lng: 90.4066 };
    expect(banani).toEqual({ lat: 23.7937, lng: 90.4066 });
  });
});
