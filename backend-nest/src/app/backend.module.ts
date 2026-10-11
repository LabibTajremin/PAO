import { type DynamicModule, Module } from '@nestjs/common';
import { type AppConfig } from '../platform/config/app-config';
import { BUSINESS_MODULES } from './business-modules';
import { platformModules } from './platform';

/** Shared infrastructure and every business module, without the HTTP edge. */
@Module({})
export class BackendModule {
  static forRoot(config?: AppConfig): DynamicModule {
    return { module: BackendModule, imports: [...platformModules(config), ...BUSINESS_MODULES] };
  }
}
