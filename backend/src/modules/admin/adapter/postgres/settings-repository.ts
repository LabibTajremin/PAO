import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { AdminErrors } from '../../app/errors';
import { type Setting } from '../../domain/settings';
import { type SettingsRepository } from '../../port/settings-repository';
import { ADMIN_OUTBOX, type AdminOutbox } from './outbox';
import { listSettings, settingByKey, updateSetting } from './sqlc/queries_sql';

/** The settings table of the admin schema. */
@Injectable()
export class PostgresSettingsRepository implements SettingsRepository {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(ADMIN_OUTBOX) private readonly outbox: AdminOutbox,
  ) {}

  listSettings(): Promise<Setting[]> {
    return listSettings(this.db.pool);
  }

  async getSetting(key: string): Promise<Setting> {
    const row = await settingByKey(this.db.pool, { key });
    if (row === null) {
      throw new DomainError(AdminErrors.SettingNotFound);
    }
    return row;
  }

  updateSetting(s: Setting, event: DomainEvent): Promise<void> {
    return this.db.transaction(async (tx) => {
      await updateSetting(tx, {
        key: s.key,
        value: s.value,
        updatedAt: s.updatedAt,
        updatedBy: s.updatedBy,
      });
      await this.outbox.write(tx, s.key, event);
    });
  }
}
