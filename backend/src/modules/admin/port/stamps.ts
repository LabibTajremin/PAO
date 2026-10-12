import { type Provider } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';

/** The time and id sources new complaints and comments are stamped with. */
export interface Stamps {
  readonly clock: Clock;
  readonly ids: IdGenerator;
}

/** Injection token for {@link Stamps}. */
export const STAMPS = Symbol('AdminStamps');

/** Provides {@link Stamps} from the platform clock and id generator. */
export const stampsProvider: Provider = {
  provide: STAMPS,
  inject: [CLOCK, ID_GENERATOR],
  useFactory: (clock: Clock, ids: IdGenerator): Stamps => ({ clock, ids }),
};
