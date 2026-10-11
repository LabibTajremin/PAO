import { Global, Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../../platform/config/app-config';
import { ObjectStore } from '../../platform/storage/object-store';
import { DocumentsController } from './adapter/http/documents.controller';
import {
  CustomerUploadsController,
  ProviderUploadsController,
} from './adapter/http/uploads.controller';
import { InprocMediaService } from './adapter/inproc/media-service';
import { PostgresMediaRepository } from './adapter/postgres/media-repository';
import { MediaJobs } from './adapter/worker/media-jobs';
import { ConfirmUpload } from './app/confirm-upload';
import { CreateUpload } from './app/create-upload';
import { MediaObjects } from './app/media-objects';
import { ViewMedia } from './app/view-media';
import { MEDIA_SERVICE } from './contract/media-service';
import { FILE_STORE, MEDIA_BUCKET, MEDIA_REPOSITORY } from './port/media-ports';

/** Presigned uploads, confirmation, audited document views and the orphan purge. */
@Global()
@Module({
  controllers: [CustomerUploadsController, ProviderUploadsController, DocumentsController],
  providers: [
    { provide: MEDIA_REPOSITORY, useClass: PostgresMediaRepository },
    { provide: FILE_STORE, useExisting: ObjectStore },
    {
      provide: MEDIA_BUCKET,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => config.s3.bucketPrivate,
    },
    CreateUpload,
    ConfirmUpload,
    ViewMedia,
    MediaObjects,
    MediaJobs,
    { provide: MEDIA_SERVICE, useClass: InprocMediaService },
  ],
  exports: [MEDIA_SERVICE],
})
export class MediaModule {}
