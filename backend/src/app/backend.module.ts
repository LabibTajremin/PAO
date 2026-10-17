import { type DynamicModule, Module } from '@nestjs/common';
import { type AppConfig } from '../platform/config/app-config';
import { BUSINESS_MODULES } from './business-modules';
import { platformModules } from './platform';

/** Shared infrastructure followed by every business module, in registration order. */
export function backendImports(config?: AppConfig): DynamicModule['imports'] {
  return [...platformModules(config), ...BUSINESS_MODULES];
}

/** Shared infrastructure and every business module, without the HTTP edge. */
@Module({})
export class BackendModule {
  static forRoot(config?: AppConfig): DynamicModule {
    return { module: BackendModule, imports: backendImports(config) };
  }
}
