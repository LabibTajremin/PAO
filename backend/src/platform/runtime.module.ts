import { Global, Module } from '@nestjs/common';
import { CLOCK, SystemClock } from './clock/clock';
import { ID_GENERATOR, UuidV7Generator } from './ids/id-generator';

/** Provides the real clock and UUIDv7 ids; tests override both tokens. */
@Global()
@Module({
  providers: [
    { provide: CLOCK, useClass: SystemClock },
    { provide: ID_GENERATOR, useClass: UuidV7Generator },
  ],
  exports: [CLOCK, ID_GENERATOR],
})
export class RuntimeModule {}
