import { type DynamicModule, Module } from '@nestjs/common';
import { type AppConfig } from '../platform/config/app-config';
import { HEALTH_ROUTES } from '../platform/health/health';
import { HealthModule } from '../platform/health/health.module';
import { HttpEdgeModule } from '../platform/http/http-edge.module';
import { UnimplementedModule } from '../platform/http/unimplemented.module';
import { backendImports } from './backend.module';

/**
 * The API composition root: shared infrastructure, the HTTP edge, every business module
 * and, last, the catch-all that answers operations no module serves yet.
 */
@Module({})
export class AppModule {
  static forRoot(config?: AppConfig): DynamicModule {
    return {
      module: AppModule,
      imports: [
        // Flat, not nested in BackendModule: Nest registers routes in module discovery
        // order, and a nested module's controllers would land after the catch-all.
        ...(backendImports(config) ?? []),
        HttpEdgeModule.forRoot({ nonSpecRoutes: HEALTH_ROUTES }),
        HealthModule,
        UnimplementedModule,
      ],
    };
  }
}
