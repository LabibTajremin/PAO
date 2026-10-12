import { Inject, Injectable } from '@nestjs/common';
import { type Setting } from '../domain/settings';
import {
  SETTINGS_CACHE,
  SETTINGS_REPOSITORY,
  type SettingsCache,
  type SettingsRepository,
} from '../port/settings-repository';

/** Reads the platform settings (A-10). */
@Injectable()
export class SettingValues {
  constructor(
    @Inject(SETTINGS_REPOSITORY) private readonly repo: SettingsRepository,
    @Inject(SETTINGS_CACHE) private readonly cache: SettingsCache,
  ) {}

  /** Lists every setting with its type and description, from the database. */
  list(): Promise<Setting[]> {
    return this.repo.listSettings();
  }

  /** Returns every value by key, from the cache when possible. */
  async values(): Promise<Record<string, string>> {
    const cached = await this.cache.read();
    if (cached !== undefined) {
      return cached;
    }
    const values: Record<string, string> = {};
    for (const s of await this.repo.listSettings()) {
      values[s.key] = s.value;
    }
    await this.cache.write(values);
    return values;
  }
}
