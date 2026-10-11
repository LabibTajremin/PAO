import { MEDIA_SERVICE, MediaErrors, MediaPurpose } from './index';

describe('media contract', () => {
  it('scopes every error reason to media', () => {
    const reasons = Object.values(MediaErrors);
    expect(reasons.every((r) => r.startsWith('media.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('matches the purpose values of the API and database', () => {
    expect(Object.values(MediaPurpose)).toEqual([
      'avatar',
      'nid_front',
      'nid_back',
      'selfie',
      'police_clearance',
      'skill_proof',
      'address_proof',
      'complaint_photo',
      'level2_photo',
    ]);
  });

  it('names its injection token after the service', () => {
    expect(MEDIA_SERVICE.description).toBe('MediaService');
  });
});
