import { Global, Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { createLogger, LOGGER } from './logger';

/** Provides the structured {@link LOGGER} at the configured level. */
@Global()
@Module({
  providers: [
    {
      provide: LOGGER,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => createLogger(config.logLevel),
    },
  ],
  exports: [LOGGER],
})
export class LoggingModule {}
