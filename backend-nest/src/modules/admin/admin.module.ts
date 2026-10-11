import { Global, Module } from '@nestjs/common';
import { SettingsController } from './adapter/http/settings.controller';
import { AdminContract } from './adapter/inproc/admin-contract';
import { PostgresComplaintRepository } from './adapter/postgres/complaint-repository';
import { adminOutboxProvider } from './adapter/postgres/outbox';
import { PostgresSettingsRepository } from './adapter/postgres/settings-repository';
import { RedisSettingsCache } from './adapter/redis/settings-cache';
import { SettingValues } from './app/setting-values';
import { UpdateSetting } from './app/update-setting';
import { ADMIN_SERVICE } from './contract/admin-service';
import { COMPLAINT_REPOSITORY } from './port/complaint-repository';
import { SETTINGS_CACHE, SETTINGS_REPOSITORY } from './port/settings-repository';

/** Settings, complaints and the admin console (ADR-0026). */
@Global()
@Module({
  controllers: [SettingsController],
  providers: [
    adminOutboxProvider,
    { provide: SETTINGS_REPOSITORY, useClass: PostgresSettingsRepository },
    { provide: COMPLAINT_REPOSITORY, useClass: PostgresComplaintRepository },
    { provide: SETTINGS_CACHE, useClass: RedisSettingsCache },
    SettingValues,
    UpdateSetting,
    { provide: ADMIN_SERVICE, useClass: AdminContract },
  ],
  exports: [ADMIN_SERVICE],
})
export class AdminModule {}
