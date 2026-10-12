import { CUSTOMER_SERVICE, CustomerErrors, CustomerEvents } from './index';

describe('customer contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(CustomerEvents).toEqual({
      CustomerProfileSaved: 'customer.CustomerProfileSaved',
    });
  });

  it('scopes every error reason to customer', () => {
    const reasons = Object.values(CustomerErrors);
    expect(reasons.every((r) => r.startsWith('customer.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('names its injection token after the service', () => {
    expect(CUSTOMER_SERVICE.description).toBe('CustomerService');
  });
});
