import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type Point } from '../../../../platform/geo/point';
import { type PerfSeeder } from '../../../../platform/seeding/seeders';
import { seedId } from '../../../catalog/contract/seed-ids';
import { ManagePresence } from '../../app/presence';

/**
 * Writes verified electricians straight into the provider and verification schemas, as
 * the Go perf seed did: enrolling thousands through the API would dominate the run.
 */
@Injectable()
export class PostgresPerfSeeder implements PerfSeeder {
  readonly serviceId = seedId('service', 'electrician');
  readonly subServiceId = seedId('sub-service', 'fan-install');

  constructor(
    @Inject(DATABASE) private readonly db: Database,
    private readonly presence: ManagePresence,
  ) {}

  async addOnlineProvider(providerId: string, at: Point): Promise<void> {
    await this.db.pool.query(
      `WITH p AS (
        INSERT INTO provider.providers (id, phone, full_name, gender, level, working_radius_m,
          rating_avg, rating_count, home_base, created_at, updated_at)
        VALUES ($1, '', 'Perf Provider', 'male', 1, 30000, 4.5, 10,
          ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, now(), now()))
      INSERT INTO provider.provider_services (provider_id, service_id) VALUES ($1, $2)`,
      [providerId, this.serviceId, at.lng, at.lat],
    );
    await this.db.pool.query(
      'INSERT INTO verification.levels (provider_id, level) VALUES ($1, 1)',
      [providerId],
    );
    await this.presence.goOnline(providerId, at);
  }
}
