import { ItemType, VERIFICATION_SERVICE, VerificationErrors, VerificationEvents } from './index';

describe('verification contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(VerificationEvents).toEqual({
      ProviderLevelChanged: 'verification.ProviderLevelChanged',
      DocumentApproved: 'verification.DocumentApproved',
      DocumentRejected: 'verification.DocumentRejected',
      DocumentExpired: 'verification.DocumentExpired',
      DocumentExpiring: 'verification.DocumentExpiring',
      Level2SessionScheduled: 'verification.Level2SessionScheduled',
      Level2ResultRecorded: 'verification.Level2ResultRecorded',
    });
  });

  it('scopes every error reason to verification', () => {
    const reasons = Object.values(VerificationErrors);
    expect(reasons.every((r) => r.startsWith('verification.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('matches the item types stored in the database', () => {
    expect(Object.values(ItemType)).toEqual([
      'nid',
      'selfie',
      'police_clearance',
      'address',
      'emergency_contact',
      'skill_proof',
      'service_area',
      'code_of_conduct',
    ]);
  });

  it('names its injection token after the service', () => {
    expect(VERIFICATION_SERVICE.description).toBe('VerificationService');
  });
});
