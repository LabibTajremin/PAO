import { Global, Module } from '@nestjs/common';
import { EnrolmentController } from './adapter/http/enrolment.controller';
import {
  PresenceController,
  ProfileController,
  PublicProfileController,
} from './adapter/http/profile.controller';
import { ProviderContract } from './adapter/inproc/provider-contract';
import { ProviderWorker } from './adapter/inproc/worker-hooks';
import {
  AdminQuality,
  CatalogServices,
  IdentityAccounts,
  MediaAvatars,
  ProviderRatings,
} from './adapter/peers/peers';
import { providerOutboxProvider } from './adapter/postgres/outbox';
import { PostgresProviderRepository } from './adapter/postgres/provider-repository';
import { ReadModelHandlers } from './adapter/postgres/read-model';
import { RedisPresence } from './adapter/redis/presence';
import { SaveEmergencyContact } from './app/emergency-contact';
import { Enrolment } from './app/enrolment';
import { FindProviders } from './app/find-nearby';
import { ManagePresence } from './app/presence';
import { ProviderProfiles, PublicProfiles } from './app/profile';
import { Profiles } from './app/profiles';
import { PROVIDER_SERVICE } from './contract/provider-service';
import { ACCOUNTS, CATALOG, MEDIA, RATINGS, SETTINGS } from './port/peers';
import { PRESENCE } from './port/presence';
import { PROVIDER_REPOSITORY } from './port/repository';

/** Enrolment profile, presence and nearby search (PRD §5, §6). */
@Global()
@Module({
  controllers: [
    EnrolmentController,
    ProfileController,
    PresenceController,
    PublicProfileController,
  ],
  providers: [
    providerOutboxProvider,
    { provide: PROVIDER_REPOSITORY, useClass: PostgresProviderRepository },
    { provide: PRESENCE, useClass: RedisPresence },
    { provide: CATALOG, useClass: CatalogServices },
    { provide: ACCOUNTS, useClass: IdentityAccounts },
    { provide: MEDIA, useClass: MediaAvatars },
    { provide: SETTINGS, useClass: AdminQuality },
    { provide: RATINGS, useClass: ProviderRatings },
    Profiles,
    Enrolment,
    SaveEmergencyContact,
    ManagePresence,
    ProviderProfiles,
    PublicProfiles,
    FindProviders,
    ReadModelHandlers,
    ProviderWorker,
    { provide: PROVIDER_SERVICE, useClass: ProviderContract },
  ],
  exports: [PROVIDER_SERVICE],
})
export class ProviderModule {}
