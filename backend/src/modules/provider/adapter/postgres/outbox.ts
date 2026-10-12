import { type Provider } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';

/** The provider module's outbox writer. */
export type ProviderOutbox = Pick<OutboxWriter, 'write'>;

/** Injection token for the {@link ProviderOutbox}. */
export const PROVIDER_OUTBOX = Symbol('ProviderOutbox');

/** Provides the writer for `provider.outbox`. */
export const providerOutboxProvider: Provider = {
  provide: PROVIDER_OUTBOX,
  inject: [ID_GENERATOR, CLOCK],
  useFactory: (ids: IdGenerator, clock: Clock) => new OutboxWriter('provider', ids, clock),
};
