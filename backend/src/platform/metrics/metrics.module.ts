import { Global, Module } from '@nestjs/common';
import { Metrics, METRICS } from './metrics';

/** Provides the process-wide {@link Metrics} registry. */
@Global()
@Module({
  providers: [{ provide: METRICS, useFactory: () => new Metrics() }],
  exports: [METRICS],
})
export class MetricsModule {}
