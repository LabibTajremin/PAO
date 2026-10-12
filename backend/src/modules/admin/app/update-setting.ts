import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { AdminEvents, type SettingChanged } from '../contract/events';
import { DomainError } from '../../../platform/errors/domain-error';
import { fitsSettingType, type Setting } from '../domain/settings';
import { AdminErrors } from './errors';
import {
  SETTINGS_CACHE,
  SETTINGS_REPOSITORY,
  type SettingsCache,
  type SettingsRepository,
} from '../port/settings-repository';

/** Changes one setting (A-10). */
@Injectable()
export class UpdateSetting {
  constructor(
    @Inject(SETTINGS_REPOSITORY) private readonly repo: SettingsRepository,
    @Inject(SETTINGS_CACHE) private readonly cache: SettingsCache,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /**
   * Validates and saves a value. SettingChanged feeds the audit trail, and the cache is
   * dropped so readers see the change at once.
   */
  async execute(actorId: string, key: string, value: string): Promise<Setting> {
    const current = await this.repo.getSetting(key);
    if (!fitsSettingType(current.type, value)) {
      throw new DomainError(AdminErrors.SettingInvalid);
    }
    const updated = { ...current, value, updatedAt: this.clock.now(), updatedBy: actorId };
    const event: SettingChanged = {
      name: AdminEvents.SettingChanged,
      key,
      before: current.value,
      after: value,
      actorId,
    };
    await this.repo.updateSetting(updated, event);
    await this.cache.invalidate();
    return updated;
  }
}
