import {
  areaValid,
  contactValid,
  dhakaDate,
  normalizePhone,
  personalProblem,
  progress,
  STEPS,
  servicesValid,
  withStep,
  withoutStep,
} from './enrolment';
import { rank } from './nearby';
import { badge, cannotGoOnline, emptyProvider } from './provider';
import { ProviderReasons } from './reasons';

const day = (s: string) => new Date(`${s}T00:00:00Z`);

describe('provider domain', () => {
  it('tracks progress with skill proof optional', () => {
    const empty = progress([]);
    expect(empty.complete).toBe(false);
    expect(empty.steps).toHaveLength(9);
    expect(empty.steps[6]).toEqual({ step: 'skill_proof', done: false, required: false });
    let done: string[] = [];
    for (const s of STEPS.filter((x) => x !== 'skill_proof')) {
      done = withStep(done, s);
    }
    done = withStep(done, 'personal');
    expect(done).toHaveLength(8);
    expect(progress(done, true)).toMatchObject({ complete: true, submitted: true });
    expect(withoutStep(done, 'personal')).toHaveLength(7);
  });

  it('validates the personal step against the 18th birthday', () => {
    const today = day('2026-10-09');
    const ok = {
      fullName: 'Rahim Uddin',
      dateOfBirth: day('2008-10-09'),
      gender: 'male',
      presentAddress: 'Banani 11',
      permanentAddress: 'Cumilla Sadar',
      bio: '',
    };
    expect(personalProblem(ok, today)).toBeUndefined();
    expect(personalProblem({ ...ok, dateOfBirth: day('2008-10-10') }, today)).toBe(
      ProviderReasons.TooYoung,
    );
    expect(personalProblem({ ...ok, gender: 'x' }, today)).toBe(ProviderReasons.Invalid);
    expect(personalProblem({ ...ok, bio: 'b'.repeat(501) }, today)).toBe(ProviderReasons.Invalid);
  });

  it('validates services, area and the emergency contact', () => {
    expect([servicesValid(0, 1), servicesValid(6, 1), servicesValid(1, 61)]).toEqual([
      false,
      false,
      false,
    ]);
    expect(servicesValid(5, 0)).toBe(true);
    const dhaka = { lat: 23.8, lng: 90.4 };
    expect(areaValid(dhaka, 999)).toBe(false);
    expect(areaValid({ lat: 90.4, lng: 23.8 }, 5000)).toBe(false);
    expect(areaValid(dhaka, 30000)).toBe(true);
    const e = { name: 'Karim', relation: 'Brother', phone: '+8801712345679', verifiedAt: null };
    expect(contactValid(e, '+8801712345678')).toBe(true);
    expect(contactValid(e, e.phone)).toBe(false);
    expect(contactValid({ ...e, name: 'K', phone: '1' }, '')).toBe(false);
  });

  it('lets only active, verified providers with an area go online', () => {
    const p = emptyProvider('p');
    const ready = { ...p, level: 1, homeBase: { lat: 0, lng: 0 }, serviceIds: ['s'] };
    expect(cannotGoOnline(ready)).toBeUndefined();
    expect(cannotGoOnline({ ...ready, accountStatus: 'suspended', level: 2 })).toBe(
      ProviderReasons.NotVerified,
    );
    expect(cannotGoOnline({ ...p, level: 1 })).toBe(ProviderReasons.NoServiceArea);
    expect([badge(0), badge(1), badge(2)]).toEqual(['none', 'verified', 'verified_pro']);
  });

  it('ranks Level 2 first, then by distance or rating', () => {
    const c = (id: string, level: number, distanceM: number, rating: number) => ({
      id,
      name: '',
      photoMediaId: null,
      gender: '',
      level,
      rating,
      ratingCount: 0,
      completedJobs: 0,
      distanceM,
    });
    const list = [c('near', 1, 100, 4), c('far', 1, 900, 4.9), c('pro', 2, 5000, 3.9)];
    expect(rank(list, false).map((x) => x.id)).toEqual(['pro', 'near', 'far']);
    expect(rank(list, true).map((x) => x.id)).toEqual(['pro', 'far', 'near']);
    const same = [c('far', 1, 900, 4), c('near', 1, 100, 4)];
    expect(rank(same, true)[0]?.id).toBe('near');
  });

  it('normalizes Bangladeshi mobile numbers', () => {
    for (const s of ['01712345678', '8801712345678', '+8801712345678', '1712345678']) {
      expect(normalizePhone(s)).toBe('+8801712345678');
    }
    for (const s of ['0171234567', '01212345678', '0171234567x']) {
      expect(normalizePhone(s)).toBeUndefined();
    }
  });

  it('takes the Dhaka calendar date', () => {
    expect(dhakaDate(new Date('2026-10-11T18:30:00Z'))).toEqual(day('2026-10-12'));
    expect(dhakaDate(new Date('2026-10-11T17:59:00Z'))).toEqual(day('2026-10-11'));
  });
});
