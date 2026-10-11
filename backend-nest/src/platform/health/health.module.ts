import { Module } from '@nestjs/common';
import type Redis from 'ioredis';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { DATABASE, type Database } from '../db/database';
import { REDIS } from '../redis/redis-client';
import { ObjectStore } from '../storage/object-store';
import { HEALTH_CHECKS, type HealthCheck, HealthController } from './health';

/** Serves /healthz and /readyz; readiness checks the database, Redis and storage. */
@Module({
  controllers: [HealthController],
  providers: [
    {
      provide: HEALTH_CHECKS,
      inject: [APP_CONFIG, DATABASE, REDIS, ObjectStore],
      useFactory: (
        config: AppConfig,
        db: Database,
        redis: Redis,
        store: ObjectStore,
      ): Record<string, HealthCheck> => ({
        database: () => db.ping(),
        redis: () => redis.ping(),
        storage: () => store.ping(config.s3.bucketPrivate),
      }),
    },
  ],
})
export class HealthModule {}
