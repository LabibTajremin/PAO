import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Setting } from '../domain/settings';

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

/**
 * Keeps setting values by key. It never fails: a cache outage is logged and reads as
 * a miss, because settings must never block a booking.
 */
export interface SettingsCache {
  read(): Promise<Record<string, string> | undefined>;
  write(values: Record<string, string>): Promise<void>;
  /** Drops the values so readers see an edit at once. */
  invalidate(): Promise<void>;
}

/** Injection token for the {@link SettingsCache}. */
export const SETTINGS_CACHE = Symbol('SettingsCache');
