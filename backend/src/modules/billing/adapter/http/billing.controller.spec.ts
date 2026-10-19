import { NOT_IMPLEMENTED } from '../../../../platform/http/api-error';
import { AdminBillingController, ProviderBillingController } from './billing.controller';

describe('billing routes on NestJS', () => {
  it('answer 501: billing is served by the .NET backend only (ADR-0035)', () => {
    const provider = new ProviderBillingController();
    const admin = new AdminBillingController();
    const calls = [
      () => provider.summary(),
      () => provider.ledger(),
      () => provider.payments(),
      () => provider.submit(),
      () => admin.payments(),
      () => admin.confirm(),
      () => admin.reject(),
      () => admin.ledger(),
    ];
    for (const call of calls) {
      expect(call).toThrow(NOT_IMPLEMENTED);
    }
  });
});
