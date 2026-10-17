import { Global, Module } from '@nestjs/common';
import { DataCipher } from '../../platform/auth/data-cipher';
import { DOCUMENT_EXPIRY } from '../../platform/testing/test-hooks';
import { ReviewController } from './adapter/http/admin.controller';
import { Level2Controller } from './adapter/http/level2.controller';
import { DocumentsController, StatusController } from './adapter/http/provider.controller';
import { VerificationContract } from './adapter/inproc/verification-contract';
import { VerificationWorker } from './adapter/inproc/worker-hooks';
import {
  AdminRules,
  CatalogServices,
  MediaDocuments,
  ProviderProfiles,
} from './adapter/peers/peers';
import { MediaFiles } from './adapter/peers/files';
import { PostgresClosures } from './adapter/postgres/closures';
import { verificationOutboxProvider } from './adapter/postgres/outbox';
import { PostgresVerificationRepository } from './adapter/postgres/verification-repository';
import { SaveDocuments } from './app/documents';
import { ExpireDocuments } from './app/expiry';
import { Level2Sessions } from './app/level2';
import { ProfileChanges } from './app/profile-changes';
import { DocumentRetention } from './app/retention';
import { ReviewItems } from './app/review';
import { States } from './app/states';
import { ProviderStatus } from './app/status';
import { Submissions } from './app/submissions';
import { VERIFICATION_SERVICE } from './contract/verification-service';
import { CLOSURES, FILES } from './port/closures';
import { CATALOG, CIPHER, MEDIA, PROVIDERS, SETTINGS } from './port/peers';
import { VERIFICATION_REPOSITORY } from './port/repository';

/** Document review, levels, Level 2 sessions and expiry (PRD §6.1–6.4). */
@Global()
@Module({
  controllers: [DocumentsController, StatusController, ReviewController, Level2Controller],
  providers: [
    verificationOutboxProvider,
    { provide: VERIFICATION_REPOSITORY, useClass: PostgresVerificationRepository },
    { provide: PROVIDERS, useClass: ProviderProfiles },
    { provide: MEDIA, useClass: MediaDocuments },
    { provide: CATALOG, useClass: CatalogServices },
    { provide: SETTINGS, useClass: AdminRules },
    { provide: CIPHER, useExisting: DataCipher },
    { provide: CLOSURES, useClass: PostgresClosures },
    { provide: FILES, useClass: MediaFiles },
    DocumentRetention,
    States,
    Submissions,
    SaveDocuments,
    ProviderStatus,
    ReviewItems,
    Level2Sessions,
    ExpireDocuments,
    ProfileChanges,
    VerificationWorker,
    { provide: DOCUMENT_EXPIRY, useExisting: ExpireDocuments },
    { provide: VERIFICATION_SERVICE, useClass: VerificationContract },
  ],
  exports: [VERIFICATION_SERVICE, DOCUMENT_EXPIRY],
})
export class VerificationModule {}
