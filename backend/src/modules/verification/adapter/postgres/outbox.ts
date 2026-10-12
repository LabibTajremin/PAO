import { type Provider } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';

/** The verification module's outbox writer. */
export type VerificationOutbox = Pick<OutboxWriter, 'write'>;

/** Injection token for the {@link VerificationOutbox}. */
export const VERIFICATION_OUTBOX = Symbol('VerificationOutbox');

/** Provides the writer for `verification.outbox`. */
export const verificationOutboxProvider: Provider = {
  provide: VERIFICATION_OUTBOX,
  inject: [ID_GENERATOR, CLOCK],
  useFactory: (ids: IdGenerator, clock: Clock) => new OutboxWriter('verification', ids, clock),
};
