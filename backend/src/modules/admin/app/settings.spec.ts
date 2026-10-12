import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { AdminErrors } from './errors';
import { type Setting } from '../domain/settings';
import { type SettingsCache, type SettingsRepository } from '../port/settings-repository';
import { SettingValues } from './setting-values';
import { UpdateSetting } from './update-setting';

const boom = new Error('boom');
const RADIUS = 'search.default_radius_m';
const radius: Setting = {
  key: RADIUS,
  value: '5000',
  type: 'integer',
  description: '',
  updatedAt: new Date(0),
  updatedBy: null,
};

class FakeRepo implements SettingsRepository {
  settings = new Map([[RADIUS, radius]]);
  events: DomainEvent[] = [];
  down = false;

  listSettings(): Promise<Setting[]> {
    return this.down ? Promise.reject(boom) : Promise.resolve([...this.settings.values()]);
  }

  getSetting(key: string): Promise<Setting> {
    const s = this.settings.get(key);
    return s ? Promise.resolve(s) : Promise.reject(new DomainError(AdminErrors.SettingNotFound));
  }

  updateSetting(s: Setting, e: DomainEvent): Promise<void> {
    if (this.down) {
      return Promise.reject(boom);
    }
    this.settings.set(s.key, s);
    this.events.push(e);
    return Promise.resolve();
  }
}

class FakeCache implements SettingsCache {
  values: Record<string, string> | undefined;

  read() {
    return Promise.resolve(this.values);
  }

  write(values: Record<string, string>) {
    this.values = values;
    return Promise.resolve();
  }

  invalidate() {
    this.values = undefined;
    return Promise.resolve();
  }
}

function setup() {
  const repo = new FakeRepo();
  const cache = new FakeCache();
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  return {
    repo,
    cache,
    values: new SettingValues(repo, cache),
    update: new UpdateSetting(repo, cache, clock),
  };
}

describe('settings', () => {
  it('caches values until an update', async () => {
    const { repo, cache, values, update } = setup();
    expect((await values.values())[RADIUS]).toBe('5000');
    expect(cache.values).toEqual({ [RADIUS]: '5000' });
    repo.settings.set(RADIUS, { ...radius, value: '1' });
    expect((await values.values())[RADIUS]).toBe('5000');
    const s = await update.execute('actor', RADIUS, '7000');
    expect(s).toMatchObject({ value: '7000', updatedBy: 'actor' });
    expect(repo.events).toEqual([
      { name: 'admin.SettingChanged', key: RADIUS, before: '1', after: '7000', actorId: 'actor' },
    ]);
    expect(cache.values).toBeUndefined();
    expect(await values.list()).toHaveLength(1);
  });

  it('refuses unknown keys and bad values, and passes database failures on', async () => {
    const { repo, values, update } = setup();
    const missing = await update.execute('a', 'missing', '1').catch((e: unknown) => e);
    expect(isDomainError(missing, AdminErrors.SettingNotFound)).toBe(true);
    const bad = await update.execute('a', RADIUS, '-1').catch((e: unknown) => e);
    expect(isDomainError(bad, AdminErrors.SettingInvalid)).toBe(true);
    repo.down = true;
    await expect(values.values()).rejects.toBe(boom);
    await expect(update.execute('a', RADIUS, '2')).rejects.toBe(boom);
  });
});
