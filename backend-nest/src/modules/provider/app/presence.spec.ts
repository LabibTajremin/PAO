import { boom, providerFixture } from '../../../../test/fakes/provider';
import { emptyProvider } from '../domain/provider';
import { ProviderReasons } from '../domain/reasons';
import { type RadiusCandidate } from '../port/repository';

const dhaka = { lat: 23.79, lng: 90.41 };
const reason = (r: string) => ({ reason: r });

function verified(f: ReturnType<typeof providerFixture>, id = 'verified'): string {
  f.repo.rows.set(id, {
    ...emptyProvider(id),
    level: 1,
    homeBase: dhaka,
    serviceIds: [f.electric],
  });
  return id;
}

describe('presence', () => {
  it('goes online, beats, and is reaped when the heartbeat stops', async () => {
    const f = providerFixture();
    const id = verified(f);
    await expect(f.manage.heartbeat(id, dhaka)).rejects.toMatchObject(
      reason(ProviderReasons.Offline),
    );
    await f.manage.goOnline(id, dhaka);
    await f.manage.heartbeat(id, { lat: 23.8, lng: 90.42 });
    expect(await f.manage.isAvailable(id)).toBe(true);
    f.presence.lostIds = [id];
    await f.manage.reapLost();
    expect(await f.manage.isAvailable(id)).toBe(false);
    expect(f.repo.events).toEqual([
      { name: 'provider.ProviderWentOffline', providerId: id, reason: 'heartbeat_lost' },
    ]);
    f.repo.rows.set('unverified', emptyProvider('unverified'));
    await expect(f.manage.goOnline('unverified', dhaka)).rejects.toMatchObject(
      reason(ProviderReasons.NotVerified),
    );
    for (const call of [
      () => f.manage.goOnline('nobody', dhaka),
      () => f.manage.heartbeat('nobody', dhaka),
      () => f.manage.goOffline('nobody', 'x'),
    ]) {
      await expect(call()).rejects.toMatchObject(reason(ProviderReasons.NotFound));
    }
    f.presence.err = boom;
    await expect(f.manage.reapLost()).rejects.toBe(boom);
  });
});

describe('profiles', () => {
  it('updates the bio, photo and language', async () => {
    const f = providerFixture();
    const id = verified(f);
    const p = await f.own.update(id, {
      bio: 'Licensed electrician',
      photoMediaId: 'ph',
      language: 'en',
    });
    expect(p).toMatchObject({ photoUrl: 'https://media/ph', bio: 'Licensed electrician' });
    expect(p.services).toHaveLength(1);
    const fr = { bio: '', photoMediaId: null, language: 'fr' };
    await expect(f.own.update(id, fr)).rejects.toMatchObject(reason(ProviderReasons.Invalid));
    f.peers.err = boom;
    await expect(f.own.update(id, { bio: '', photoMediaId: 'ph', language: 'en' })).rejects.toBe(
      boom,
    );
    await expect(f.own.own(id)).rejects.toBe(boom);
    f.peers.err = undefined;
    f.repo.err = boom;
    const plain = { bio: '', photoMediaId: null, language: 'en' };
    await expect(f.own.update(id, plain)).rejects.toBe(boom);
    f.repo.err = undefined;
    f.repo.getErr = boom;
    await expect(f.own.own(id)).rejects.toBe(boom);
    await expect(f.profiles.get(id)).rejects.toBe(boom);
  });

  it('shows customers verified, active providers only', async () => {
    const f = providerFixture();
    const id = verified(f);
    const shown = await f.public.get('viewer', id);
    expect(shown).toMatchObject({ photoUrl: '', rating: { average: 4.5 } });
    f.repo.rows.set('new', emptyProvider('new'));
    await expect(f.public.get('viewer', 'new')).rejects.toMatchObject(
      reason(ProviderReasons.NotFound),
    );
    const banned = { ...emptyProvider('b'), level: 1, accountStatus: 'banned' };
    f.repo.rows.set('b', banned);
    await expect(f.public.get('viewer', 'b')).rejects.toMatchObject(
      reason(ProviderReasons.NotFound),
    );
  });
});

function candidate(id: string, gender: string, level: number): RadiusCandidate {
  const base = { name: '', photoMediaId: null, rating: 0, ratingCount: 0, completedJobs: 0 };
  return { ...base, id, gender, level, distanceM: 0, workingRadiusM: 5000 };
}

describe('find nearby', () => {
  it('ranks, honours women-only services and the working radius', async () => {
    const f = providerFixture();
    const salon = 'salon';
    const name = { en: 'Salon', bn: 'সেলুন' };
    f.peers.services.set(salon, {
      id: salon,
      name,
      published: true,
      minLevel: 1,
      womenProvidersOnly: true,
    });
    f.presence.hits = [
      { id: 'a', distanceM: 300 },
      { id: 'b', distanceM: 900 },
      { id: 'c', distanceM: 1500 },
      { id: 'far', distanceM: 6000 },
    ];
    f.repo.candidateRows = [
      candidate('a', 'male', 1),
      candidate('b', 'female', 1),
      candidate('c', 'female', 2),
      candidate('far', 'female', 2),
    ];
    const q = { at: dhaka, radiusM: 10000, womenOnly: false, byRating: false, limit: 5 };
    const salonHits = await f.finder.nearby({ ...q, serviceId: salon });
    expect(salonHits.map((c) => [c.id, c.distanceM])).toEqual([
      ['c', 1500],
      ['b', 900],
    ]);
    const electric = await f.finder.nearby({ ...q, serviceId: f.electric, limit: 2 });
    expect(electric.map((c) => c.id)).toEqual(['c', 'a']);
    expect(await f.finder.nearby({ ...q, serviceId: f.electric, limit: 0 })).toHaveLength(3);
    f.presence.hits = [];
    expect(await f.finder.nearby({ ...q, serviceId: f.electric })).toEqual([]);
    await expect(f.finder.nearby({ ...q, serviceId: 'unknown' })).rejects.toMatchObject(
      reason(ProviderReasons.UnknownService),
    );
  });

  it('adds the live online flag to the admin list', async () => {
    const f = providerFixture();
    const record = {
      id: 'p',
      name: 'Rahim',
      phone: '+8801712345678',
      status: 'active',
      level: 1,
      serviceIds: [],
      rating: 0,
      ratingCount: 0,
      completedJobs: 0,
      flagged: false,
      flagReason: '',
      online: false,
      createdAt: new Date(),
    };
    f.repo.records = [record];
    await f.presence.online('p', [], dhaka);
    const query = {
      id: null,
      text: '',
      status: '',
      level: null,
      flagged: null,
      afterAt: null,
      afterId: null,
      limit: 20,
    };
    expect(await f.finder.search(query)).toEqual([{ ...record, online: true }]);
  });
});
