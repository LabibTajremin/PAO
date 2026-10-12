import { Global, Inject, Module, type OnApplicationShutdown } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { ObjectStore } from './object-store';

/** Opens object storage and prepares the private and public buckets at start-up. */
@Global()
@Module({
  providers: [
    {
      provide: ObjectStore,
      inject: [APP_CONFIG],
      useFactory: async (config: AppConfig) => {
        const store = new ObjectStore(config.s3);
        try {
          for (const bucket of [config.s3.bucketPrivate, config.s3.bucketPublic]) {
            await store.ensureBucket(bucket);
          }
        } catch (cause) {
          store.close();
          throw new Error('prepare storage', { cause });
        }
        return store;
      },
    },
  ],
  exports: [ObjectStore],
})
export class StorageModule implements OnApplicationShutdown {
  constructor(@Inject(ObjectStore) private readonly store: ObjectStore) {}

  onApplicationShutdown(): void {
    this.store.close();
  }
}
