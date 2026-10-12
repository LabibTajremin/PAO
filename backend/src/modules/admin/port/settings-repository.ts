import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Setting } from '../domain/settings';
import { type CachedValue } from './console';

/** Stores the platform settings. */
export interface SettingsRepository {
  listSettings(): Promise<Setting[]>;
  /** Returns the setting, or throws `admin.setting_not_found`. */
  getSetting(key: string): Promise<Setting>;
  /** Saves the value and writes `event` to the outbox in one transaction. */
  updateSetting(setting: Setting, event: DomainEvent): Promise<void>;
}

/** Injection token for the {@link SettingsRepository}. */
export const SETTINGS_REPOSITORY = Symbol('SettingsRepository');

/** Setting values by key, kept between reads. */
export type SettingsCache = CachedValue<Record<string, string>>;

/** Injection token for the {@link SettingsCache}. */
export const SETTINGS_CACHE = Symbol('SettingsCache');
