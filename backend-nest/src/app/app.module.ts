import { type DynamicModule, Module } from '@nestjs/common';
import { type AppConfig } from '../platform/config/app-config';
import { HEALTH_ROUTES } from '../platform/health/health';
import { HealthModule } from '../platform/health/health.module';
import { HttpEdgeModule } from '../platform/http/http-edge.module';
import { UnimplementedModule } from '../platform/http/unimplemented.module';
import { BUSINESS_MODULES } from './business-modules';
import { platformModules } from './platform';

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
        ...platformModules(config),
        HttpEdgeModule.forRoot({ nonSpecRoutes: HEALTH_ROUTES }),
        HealthModule,
        ...BUSINESS_MODULES,
        UnimplementedModule,
      ],
    };
  }
}
