import { type INestApplicationContext } from '@nestjs/common';
import { type AppConfig } from '../platform/config/app-config';
import { ConfigModule } from '../platform/config/config.module';
import { DatabaseModule } from '../platform/db/database.module';
import { LoggingModule } from '../platform/logging/logging.module';
import { MetricsModule } from '../platform/metrics/metrics.module';
import { RbacModule } from '../platform/rbac/rbac.module';
import { RedisModule } from '../platform/redis/redis.module';
import { RuntimeModule } from '../platform/runtime.module';
import { StorageModule } from '../platform/storage/storage.module';
import { AuthModule } from '../platform/auth/auth.module';
import {
  DOCUMENT_EXPIRY,
  type DocumentExpiry,
  PUSH_CAPTURE,
  type PushCapture,
  SMS_CAPTURE,
  type SmsCapture,
  type TestHookSeams,
} from '../platform/testing/test-hooks';

/** The shared infrastructure both the API and the worker run on. */
export function platformModules(config?: AppConfig) {
  return [
    ConfigModule.forRoot(config),
    RuntimeModule,
    LoggingModule,
    MetricsModule,
    DatabaseModule,
    RedisModule,
    StorageModule,
    AuthModule,
    RbacModule,
  ];
}

/** Returns the provider for `token`, or undefined when no module provides it. */
function optionalProvider(app: INestApplicationContext, token: symbol): unknown {
  try {
    return app.get(token, { strict: false });
  } catch {
    return undefined;
  }
}

/** The test-hook seams the modules provide, where they exist yet. */
export function testHookSeams(app: INestApplicationContext): TestHookSeams {
  return {
    sms: optionalProvider(app, SMS_CAPTURE) as SmsCapture | undefined,
    push: optionalProvider(app, PUSH_CAPTURE) as PushCapture | undefined,
    expiry: optionalProvider(app, DOCUMENT_EXPIRY) as DocumentExpiry | undefined,
  };
}
