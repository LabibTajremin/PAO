import { AUDIT_SERVICE } from './index';

describe('audit contract', () => {
  it('names its injection token after the service', () => {
    expect(AUDIT_SERVICE.description).toBe('AuditService');
  });
});
