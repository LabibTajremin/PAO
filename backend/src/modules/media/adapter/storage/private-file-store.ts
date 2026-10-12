import { Inject, Injectable } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../../../../platform/config/app-config';
import {
  type ObjectInfo,
  ObjectStore,
  type PresignedUpload,
} from '../../../../platform/storage/object-store';
import { type FileStore } from '../../port/media-ports';

/** The platform object store, uploading to the private bucket. */
@Injectable()
export class PrivateFileStore implements FileStore {
  readonly uploadBucket: string;

  constructor(
    @Inject(ObjectStore) private readonly store: ObjectStore,
    @Inject(APP_CONFIG) config: AppConfig,
  ) {
    this.uploadBucket = config.s3.bucketPrivate;
  }

  presignPut(req: Parameters<ObjectStore['presignPut']>[0]): Promise<PresignedUpload> {
    return this.store.presignPut(req);
  }

  presignGet(bucket: string, key: string, ttlSeconds: number): Promise<string> {
    return this.store.presignGet(bucket, key, ttlSeconds);
  }

  head(bucket: string, key: string): Promise<ObjectInfo> {
    return this.store.head(bucket, key);
  }

  delete(bucket: string, key: string): Promise<void> {
    return this.store.delete(bucket, key);
  }
}
