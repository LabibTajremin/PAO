import { type SettingValues } from '../../app/setting-values';
import { type ComplaintRepository } from '../../port/complaint-repository';
import { AdminContract } from './admin-contract';

function contract(values: Record<string, string>) {
  const settings = { values: () => Promise.resolve(values) } as unknown as SettingValues;
  const complaints = {
    countVerifiedComplaints: (id: string) => Promise.resolve(id === 'p' ? 2 : 0),
  } as unknown as ComplaintRepository;
  return new AdminContract(settings, complaints);
}

describe('AdminContract', () => {
  it('reads typed settings', async () => {
    const s = await contract({
      'booking.accept_timeout_asap_seconds': '240',
      'quality.rating_floor': '4.25',
      'documents.retention_days': '30',
      'service_area.geojson': '{"type":"Polygon"}',
    }).getSettings();
    expect(s).toMatchObject({
      acceptTimeoutAsapMs: 240_000,
      ratingFloor: 4.25,
      documentRetentionMs: 30 * 86_400_000,
      serviceAreaGeoJson: '{"type":"Polygon"}',
    });
  });

  it('falls back to the defaults for missing or damaged values', async () => {
    const s = await contract({
      'quality.rating_floor': 'x',
      'search.default_radius_m': '1.5',
    }).getSettings();
    expect(s).toEqual({
      acceptTimeoutAsapMs: 180_000,
      acceptTimeoutScheduledMs: 1_800_000,
      defaultSearchRadiusM: 5000,
      ratingFloor: 3.5,
      ratingMinJobs: 10,
      maxProviderCancellations30d: 3,
      startCodeMaxAttempts: 5,
      startCodeLockoutMs: 600_000,
      policeClearanceValidityMs: 365 * 86_400_000,
      level2CoolingOffMs: 14 * 86_400_000,
      documentRetentionMs: 365 * 86_400_000,
      serviceAreaGeoJson: '',
    });
  });

  it('counts verified complaints', async () => {
    expect(await contract({}).countVerifiedComplaints('p')).toBe(2);
  });
});
