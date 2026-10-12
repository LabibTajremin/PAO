import { Global, Module } from '@nestjs/common';
import {
  ComplaintsController,
  CustomerReportsController,
  ProviderReportsController,
} from './adapter/http/complaints.controller';
import { DashboardController } from './adapter/http/dashboard.controller';
import {
  AdminCustomersController,
  AdminProvidersController,
} from './adapter/http/people.controller';
import { SettingsController } from './adapter/http/settings.controller';
import { AdminContract } from './adapter/inproc/admin-contract';
import { LazyConsole } from './adapter/peers/console';
import { BookingParties, IdentityAdmins, MediaEvidencePhotos } from './adapter/peers/peers';
import { PostgresComplaintRepository } from './adapter/postgres/complaint-repository';
import { PostgresDashboardRepository } from './adapter/postgres/dashboard-repository';
import { adminOutboxProvider } from './adapter/postgres/outbox';
import { PostgresSettingsRepository } from './adapter/postgres/settings-repository';
import { StatsSubscribers } from './adapter/postgres/stats-subscribers';
import { cachedValueProvider } from './adapter/redis/cached-value';
import { CustomerConsole } from './app/customer-console';
import { ProviderConsole } from './app/provider-console';
import { DASHBOARD_CACHE, ReadDashboard } from './app/read-dashboard';
import { ReportProblem } from './app/report-problem';
import { SettingValues } from './app/setting-values';
import { UpdateSetting } from './app/update-setting';
import { WorkComplaints } from './app/work-complaints';
import { ADMIN_SERVICE } from './contract/admin-service';
import { COMPLAINT_REPOSITORY } from './port/complaint-repository';
import { CONSOLE } from './port/console';
import { DASHBOARD_REPOSITORY } from './port/dashboard-repository';
import { ADMINS, BOOKINGS, EVIDENCE_PHOTOS } from './port/peers';
import { SETTINGS_CACHE, SETTINGS_REPOSITORY } from './port/settings-repository';
import { stampsProvider } from './port/stamps';

/** Settings, complaints, the dashboard and the people console (ADR-0026). */
@Global()
@Module({
  controllers: [
    SettingsController,
    ComplaintsController,
    CustomerReportsController,
    ProviderReportsController,
    DashboardController,
    AdminProvidersController,
    AdminCustomersController,
  ],
  providers: [
    adminOutboxProvider,
    stampsProvider,
    { provide: SETTINGS_REPOSITORY, useClass: PostgresSettingsRepository },
    { provide: COMPLAINT_REPOSITORY, useClass: PostgresComplaintRepository },
    { provide: DASHBOARD_REPOSITORY, useClass: PostgresDashboardRepository },
    // A lost invalidation leaves values stale for at most ten minutes.
    cachedValueProvider(SETTINGS_CACHE, 'settings', 10 * 60_000),
    cachedValueProvider(DASHBOARD_CACHE, 'dashboard', 60_000),
    { provide: CONSOLE, useClass: LazyConsole },
    { provide: BOOKINGS, useClass: BookingParties },
    { provide: EVIDENCE_PHOTOS, useClass: MediaEvidencePhotos },
    { provide: ADMINS, useClass: IdentityAdmins },
    SettingValues,
    UpdateSetting,
    ReportProblem,
    WorkComplaints,
    ReadDashboard,
    ProviderConsole,
    CustomerConsole,
    StatsSubscribers,
    { provide: ADMIN_SERVICE, useClass: AdminContract },
  ],
  exports: [ADMIN_SERVICE],
})
export class AdminModule {}
