import { Inject, Injectable } from '@nestjs/common';
import { SettingValues } from '../../app/setting-values';
import { type AdminService } from '../../contract/admin-service';
import { type Settings } from '../../contract/dto';
import { COMPLAINT_REPOSITORY, type ComplaintRepository } from '../../port/complaint-repository';

const SECOND_MS = 1000;
const DAY_MS = 24 * 60 * 60 * SECOND_MS;

// The seeded values (docs/build/04-decisions.md), so a missing or damaged row cannot
// stop bookings.
const DEFAULTS: Readonly<Record<string, string>> = {
  'booking.accept_timeout_asap_seconds': '180',
  'booking.accept_timeout_scheduled_seconds': '1800',
  'booking.start_code_max_attempts': '5',
  'booking.start_code_lockout_seconds': '600',
  'search.default_radius_m': '5000',
  'quality.rating_floor': '3.5',
  'quality.rating_min_jobs': '10',
  'quality.max_provider_cancellations_30d': '3',
  'verification.police_clearance_validity_days': '365',
  'verification.level2_cooling_off_days': '14',
  'documents.retention_days': '365',
};

/** Reads typed values, falling back to the default when a value does not parse. */
class Values {
  constructor(private readonly values: Readonly<Record<string, string>>) {}

  int(key: string): number {
    const n = Number(this.values[key]);
    return /^[+-]?\d+$/.test(this.values[key] ?? '') && Number.isSafeInteger(n)
      ? n
      : Number(DEFAULTS[key]);
  }

  float(key: string): number {
    const f = Number(this.values[key]);
    return (this.values[key] ?? '').trim() !== '' && !Number.isNaN(f) ? f : Number(DEFAULTS[key]);
  }

  text(key: string): string {
    return this.values[key] ?? '';
  }
}

/** The admin contract for other modules. */
@Injectable()
export class AdminContract implements AdminService {
  constructor(
    private readonly settings: SettingValues,
    @Inject(COMPLAINT_REPOSITORY) private readonly complaints: ComplaintRepository,
  ) {}

  async getSettings(): Promise<Settings> {
    const v = new Values(await this.settings.values());
    return {
      acceptTimeoutAsapMs: v.int('booking.accept_timeout_asap_seconds') * SECOND_MS,
      acceptTimeoutScheduledMs: v.int('booking.accept_timeout_scheduled_seconds') * SECOND_MS,
      defaultSearchRadiusM: v.int('search.default_radius_m'),
      ratingFloor: v.float('quality.rating_floor'),
      ratingMinJobs: v.int('quality.rating_min_jobs'),
      maxProviderCancellations30d: v.int('quality.max_provider_cancellations_30d'),
      startCodeMaxAttempts: v.int('booking.start_code_max_attempts'),
      startCodeLockoutMs: v.int('booking.start_code_lockout_seconds') * SECOND_MS,
      policeClearanceValidityMs: v.int('verification.police_clearance_validity_days') * DAY_MS,
      level2CoolingOffMs: v.int('verification.level2_cooling_off_days') * DAY_MS,
      documentRetentionMs: v.int('documents.retention_days') * DAY_MS,
      serviceAreaGeoJson: v.text('service_area.geojson'),
    };
  }

  countVerifiedComplaints(againstId: string): Promise<number> {
    return this.complaints.countVerifiedComplaints(againstId);
  }
}
