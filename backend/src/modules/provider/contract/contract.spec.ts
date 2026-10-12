import {
  EnrolmentStep,
  Gender,
  PROVIDER_SERVICE,
  ProviderErrors,
  ProviderEvents,
  SortOrder,
} from './index';

describe('provider contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(ProviderEvents).toEqual({
      EnrolmentStepSaved: 'provider.EnrolmentStepSaved',
      ProviderFlaggedForReview: 'provider.ProviderFlaggedForReview',
      ProviderWentOffline: 'provider.ProviderWentOffline',
    });
  });

  it('scopes every error reason to provider', () => {
    const reasons = Object.values(ProviderErrors);
    expect(reasons.every((r) => r.startsWith('provider.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('lists the enrolment steps in wizard order', () => {
    expect(Object.values(EnrolmentStep)).toEqual([
      'personal',
      'services',
      'area',
      'nid',
      'selfie',
      'police_clearance',
      'skill_proof',
      'emergency_contact',
      'code_of_conduct',
    ]);
  });

  it('matches the gender and sort values of the API', () => {
    expect(Object.values(Gender)).toEqual(['female', 'male', 'other']);
    expect(Object.values(SortOrder)).toEqual(['distance', 'rating']);
  });

  it('names its injection token after the service', () => {
    expect(PROVIDER_SERVICE.description).toBe('ProviderService');
  });
});
