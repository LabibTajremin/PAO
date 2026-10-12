import { type DynamicModule, Global, Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from './app-config';
import { loadConfig } from './load-config';

/**
 * Provides the {@link AppConfig} to every module. The entry points read it from the
 * environment; tests pass a ready-made configuration.
 */
@Global()
@Module({})
export class ConfigModule {
  static forRoot(config?: AppConfig): DynamicModule {
    return {
      module: ConfigModule,
      providers: [{ provide: APP_CONFIG, useFactory: () => config ?? loadConfig(process.env) }],
      exports: [APP_CONFIG],
    };
  }
}
