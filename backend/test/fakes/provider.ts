// In-memory stand-ins for the provider ports, for unit specs.
import { DomainError } from '../../src/platform/errors/domain-error';
import { type DomainEvent } from '../../src/platform/events/domain-event';
import { FakeClock } from '../../src/platform/clock/fake-clock';
import { type ProviderQuery, type ProviderRecord } from '../../src/modules/provider/contract';
import {
  emptyProvider,
  type Point,
  type Provider,
} from '../../src/modules/provider/domain/provider';
import { ProviderReasons } from '../../src/modules/provider/domain/reasons';
import {
  type Accounts,
  type Catalog,
  type Media,
  type Quality,
  type Rating,
  type Ratings,
  type Service,
  type Settings,
} from '../../src/modules/provider/port/peers';
import { type Hit, type Presence } from '../../src/modules/provider/port/presence';
import {
  type ProviderRepository,
  type RadiusCandidate,
} from '../../src/modules/provider/port/repository';
import { Enrolment } from '../../src/modules/provider/app/enrolment';
import { SaveEmergencyContact } from '../../src/modules/provider/app/emergency-contact';
import { FindProviders } from '../../src/modules/provider/app/find-nearby';
import { ManagePresence } from '../../src/modules/provider/app/presence';
import { ProviderProfiles, PublicProfiles } from '../../src/modules/provider/app/profile';
import { Profiles } from '../../src/modules/provider/app/profiles';

/** The error fakes fail with. */
export const boom = new Error('boom');

/** Profiles in a map; `err` fails writes, `getErr` fails reads. */
export class FakeProviderRepo implements ProviderRepository {
  rows = new Map<string, Provider>();
  events: DomainEvent[] = [];
  err?: Error;
  getErr?: Error;
  candidateRows: RadiusCandidate[] = [];
  records: ProviderRecord[] = [];

  ensure(id: string, phone: string, at: Date): Promise<void> {
    if (this.err) {
      return Promise.reject(this.err);
    }
    this.rows.set(id, emptyProvider(id, phone, at));
    return Promise.resolve();
  }

  get(id: string): Promise<Provider> {
    const p = this.rows.get(id);
    if (this.getErr) {
      return Promise.reject(this.getErr);
    }
    return p ? Promise.resolve(p) : Promise.reject(new DomainError(ProviderReasons.NotFound));
  }

  save(p: Provider, events: readonly DomainEvent[] = []): Promise<void> {
    if (this.err) {
      return Promise.reject(this.err);
    }
    this.rows.set(p.id, p);
    this.events.push(...events);
    return Promise.resolve();
  }

  publish(_id: string, events: readonly DomainEvent[]): Promise<void> {
    this.events.push(...events);
    return this.err ? Promise.reject(this.err) : Promise.resolve();
  }

  candidates(): Promise<RadiusCandidate[]> {
    return Promise.resolve(this.candidateRows);
  }

  search(_q: ProviderQuery): Promise<ProviderRecord[]> {
    return Promise.resolve(this.records);
  }
}

/** Presence in a set; `hits` answers every nearby search. */
export class FakePresence implements Presence {
  ids = new Set<string>();
  lostIds: string[] = [];
  hits: Hit[] = [];
  err?: Error;

  online(id: string, _s: readonly string[], _at: Point): Promise<void> {
    this.ids.add(id);
    return Promise.resolve();
  }

  beat(id: string, s: readonly string[], at: Point): Promise<void> {
    if (!this.ids.has(id)) {
      return Promise.reject(new DomainError(ProviderReasons.Offline));
    }
    return this.online(id, s, at);
  }

  offline(id: string): Promise<void> {
    if (this.err) {
      return Promise.reject(this.err);
    }
    this.ids.delete(id);
    return Promise.resolve();
  }

  isOnline(id: string): Promise<boolean> {
    return Promise.resolve(this.ids.has(id));
  }

  near(): Promise<Hit[]> {
    return Promise.resolve(this.hits);
  }

  lost(): Promise<string[]> {
    return Promise.resolve(this.lostIds);
  }
}

/** Catalog, identity, media, settings and ratings at once. */
export class FakeProviderPeers implements Catalog, Accounts, Media, Settings, Ratings {
  services = new Map<string, Service>();
  sent: string[] = [];
  codeErr?: Error;
  err?: Error;

  private fail(): Promise<never> | undefined {
    return this.err ? Promise.reject(this.err) : undefined;
  }

  service(id: string): Promise<Service> {
    const s = this.services.get(id);
    return s ? Promise.resolve(s) : Promise.reject(new DomainError(ProviderReasons.UnknownService));
  }

  phone(): Promise<string> {
    return this.fail() ?? Promise.resolve('+8801712345678');
  }

  sendContactCode(phone: string): Promise<void> {
    if (this.codeErr) {
      return Promise.reject(this.codeErr);
    }
    this.sent.push(phone);
    return Promise.resolve();
  }

  checkContactCode(): Promise<void> {
    return this.codeErr ? Promise.reject(this.codeErr) : Promise.resolve();
  }

  attachAvatar(): Promise<void> {
    return this.fail() ?? Promise.resolve();
  }

  url(_viewer: string, id: string): Promise<string> {
    return this.fail() ?? Promise.resolve(`https://media/${id}`);
  }

  quality(): Promise<Quality> {
    return Promise.resolve({ ratingFloor: 3.5, ratingMinJobs: 10, maxCancellations: 3 });
  }

  providerRating(): Promise<Rating> {
    return Promise.resolve({ average: 4.5, count: 2, distribution: [0, 0, 0, 1, 1] });
  }
}

/** The provider use cases over fakes. */
export function providerFixture() {
  const repo = new FakeProviderRepo();
  const presence = new FakePresence();
  const peers = new FakeProviderPeers();
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const electric = '0192a000-0000-7000-8000-000000000001';
  peers.services.set(electric, {
    id: electric,
    name: { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' },
    published: true,
    minLevel: 1,
    womenProvidersOnly: false,
  });
  const profiles = new Profiles(repo, peers, clock);
  return {
    repo,
    presence,
    peers,
    clock,
    electric,
    profiles,
    enrolment: new Enrolment(profiles, repo, peers, presence),
    contact: new SaveEmergencyContact(profiles, peers),
    manage: new ManagePresence(repo, presence),
    own: new ProviderProfiles(profiles, presence, peers, peers),
    public: new PublicProfiles(profiles, peers, peers, peers),
    finder: new FindProviders(repo, presence, peers),
  };
}
