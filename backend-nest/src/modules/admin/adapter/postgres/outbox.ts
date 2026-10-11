import { type Provider } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';

/** The admin module's outbox writer. */
export type AdminOutbox = Pick<OutboxWriter, 'write'>;

/** Injection token for the {@link AdminOutbox}. */
export const ADMIN_OUTBOX = Symbol('AdminOutbox');

/** Provides the writer for `admin.outbox`. */
export const adminOutboxProvider: Provider = {
  provide: ADMIN_OUTBOX,
  inject: [ID_GENERATOR, CLOCK],
  useFactory: (ids: IdGenerator, clock: Clock) => new OutboxWriter('admin', ids, clock),
};
