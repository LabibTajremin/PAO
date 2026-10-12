// In-memory stand-ins for the verification ports, for unit specs.
import { FakeClock } from '../../src/platform/clock/fake-clock';
import { DomainError } from '../../src/platform/errors/domain-error';
import { type DomainEvent } from '../../src/platform/events/domain-event';
import { UuidV7Generator } from '../../src/platform/ids/id-generator';
import { type Provider } from '../../src/modules/provider/contract/dto';
import {
  type EnrolmentStatus,
  type EnrolmentStep,
} from '../../src/modules/provider/contract/enrolment';
import { SaveDocuments } from '../../src/modules/verification/app/documents';
import { ExpireDocuments } from '../../src/modules/verification/app/expiry';
import { Level2Sessions } from '../../src/modules/verification/app/level2';
import { ProfileChanges } from '../../src/modules/verification/app/profile-changes';
import { ReviewItems } from '../../src/modules/verification/app/review';
import { States } from '../../src/modules/verification/app/states';
import { ProviderStatus } from '../../src/modules/verification/app/status';
import { Submissions } from '../../src/modules/verification/app/submissions';
import { ITEM_TYPES } from '../../src/modules/verification/domain/items';
import { type Session } from '../../src/modules/verification/domain/level2';
import { VerificationReasons } from '../../src/modules/verification/domain/reasons';
import { newState, type State } from '../../src/modules/verification/domain/state';
import {
  type Catalog,
  type Cipher,
  type Media,
  type Providers,
  type Rules,
  type Service,
  type Settings,
} from '../../src/modules/verification/port/peers';
import {
  type Change,
  type ExpiringItem,
  type QueueRow,
  type VerificationRepository,
} from '../../src/modules/verification/port/repository';

/** The error fakes fail with. */
export const boom = new Error('boom');

const DAY_MS = 24 * 60 * 60 * 1000;

function copy(st: State): State {
  return { ...st, items: new Map(st.items), sessions: [...st.sessions], newDocuments: [] };
}

/** States in a map; `err` fails every call, `listErr` the sweeps and lists. */
export class FakeVerificationRepo implements VerificationRepository {
  states = new Map<string, State>();
  events: DomainEvent[] = [];
  blocked = new Set<string>();
  expiring: ExpiringItem[] = [];
  reminded = new Set<string>();
  queueRows: QueueRow[] = [];
  err?: Error;
  listErr?: Error;

  private result<T>(v: T, err = this.err): Promise<T> {
    return err ? Promise.reject(err) : Promise.resolve(v);
  }

  load(id: string): Promise<State> {
    return this.result(copy(this.states.get(id) ?? newState(id)));
  }

  async change(id: string, fn: Change): Promise<State> {
    const st = await this.load(id);
    const events = await fn(st);
    st.nidChanged = false;
    this.states.set(id, st);
    this.events.push(...events);
    return st;
  }

  levels(ids: readonly string[]): Promise<Map<string, number>> {
    return this.result(new Map(ids.map((id) => [id, this.states.get(id)?.level ?? 0])));
  }

  countPendingReviews(): Promise<number> {
    return this.result(this.states.size);
  }

  queue(): Promise<QueueRow[]> {
    return this.result(this.queueRows, this.listErr);
  }

  sessions(): Promise<Session[]> {
    return this.result([], this.listErr);
  }

  session(id: string): Promise<Session> {
    for (const st of this.states.values()) {
      const s = st.sessions.find((x) => x.id === id);
      if (s) {
        return Promise.resolve(s);
      }
    }
    return Promise.reject(new DomainError(VerificationReasons.NotFound));
  }

  expiredBy(t: Date): Promise<string[]> {
    const ids = [...this.states.values()]
      .filter((st) =>
        [...st.items.values()].some(
          (it) => it.status === 'approved' && it.expiresAt !== null && it.expiresAt <= t,
        ),
      )
      .map((st) => st.providerId);
    return this.result(ids, this.listErr);
  }

  expiringBetween(): Promise<ExpiringItem[]> {
    return this.result(this.expiring, this.listErr);
  }

  remindOnce(it: ExpiringItem, days: number, e: DomainEvent): Promise<boolean> {
    const key = `${it.providerId}/${it.itemType}/${days}`;
    const fresh = !this.reminded.has(key);
    if (fresh) {
      this.reminded.add(key);
      this.events.push(e);
    }
    return this.result(fresh);
  }

  nidBlocked(hash: string): Promise<boolean> {
    return this.result(this.blocked.has(hash));
  }

  blockNid(id: string): Promise<void> {
    const nid = this.states.get(id)?.nid;
    if (nid) {
      this.blocked.add(nid.hash);
    }
    return this.result(undefined);
  }
}

/** Provider, media, catalog and settings at once. */
export class FakeVerificationPeers implements Providers, Media, Catalog, Settings {
  providers = new Map<string, Provider>();
  steps = new Map<string, string[]>();
  submitErr?: Error;
  mediaErr?: Error;
  err?: Error;

  get(id: string): Promise<Provider> {
    const p = this.providers.get(id);
    if (!p) {
      return Promise.reject(new DomainError(VerificationReasons.NotFound));
    }
    return this.err ? Promise.reject(this.err) : Promise.resolve(p);
  }

  markStepDone(id: string, step: EnrolmentStep): Promise<EnrolmentStatus> {
    this.steps.set(id, [...(this.steps.get(id) ?? []), step]);
    return Promise.resolve({ steps: [], complete: false, submitted: false });
  }

  markSubmitted(): Promise<void> {
    return this.submitErr ? Promise.reject(this.submitErr) : Promise.resolve();
  }

  attach(): Promise<void> {
    return this.mediaErr ? Promise.reject(this.mediaErr) : Promise.resolve();
  }

  service(id: string): Promise<Service> {
    const s = { id, name: { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' }, minLevel: 1 };
    return this.err ? Promise.reject(this.err) : Promise.resolve(s);
  }

  rules(): Promise<Rules> {
    const r = {
      policeClearanceValidityMs: 365 * DAY_MS,
      level2CoolingOffMs: 14 * DAY_MS,
      documentRetentionMs: 365 * DAY_MS,
    };
    return this.err ? Promise.reject(this.err) : Promise.resolve(r);
  }
}

/** Prefixes instead of encrypting; `broken` fails decryption. */
export class FakeCipher implements Cipher {
  broken = false;

  encrypt(b: Buffer): Buffer {
    return Buffer.concat([Buffer.from('enc:'), b]);
  }

  decrypt(b: Buffer): Buffer {
    if (this.broken) {
      throw boom;
    }
    return b.subarray(4);
  }

  lookupHash(v: string): string {
    return `h:${v}`;
  }
}

/** A provider as the provider contract returns it. */
export function providerOf(id: string): Provider {
  return {
    id,
    fullName: 'Rahim',
    dateOfBirth: new Date('1990-04-12T00:00:00Z'),
    gender: 'male',
    presentAddress: 'Banani',
    permanentAddress: 'Cumilla',
    phone: '+8801712345678',
    photoMediaId: null,
    serviceIds: ['0192a000-0000-7000-8000-000000000001'],
    experienceYears: 8,
    homeBase: { lat: 23.79, lng: 90.41 },
    workingRadiusM: 8000,
    language: 'bn',
    emergencyContact: {
      name: 'Karim',
      relation: 'Brother',
      phone: '+8801812345678',
      verifiedAt: null,
    },
    submittedAt: null,
  };
}

/** The verification use cases over fakes. */
export function verificationFixture() {
  const id = '0192a000-0000-7000-8000-0000000000aa';
  const repo = new FakeVerificationRepo();
  const peers = new FakeVerificationPeers();
  peers.providers.set(id, providerOf(id));
  const cipher = new FakeCipher();
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const states = new States(repo, peers, clock, new UuidV7Generator());
  const submissions = new Submissions(states, peers, peers);
  return {
    id,
    repo,
    peers,
    cipher,
    clock,
    states,
    documents: new SaveDocuments(submissions, states, peers, cipher),
    status: new ProviderStatus(states, peers, peers),
    review: new ReviewItems(states, peers, cipher),
    level2: new Level2Sessions(states, peers, peers),
    expiry: new ExpireDocuments(states),
    changes: new ProfileChanges(states, peers),
  };
}

type Fixture = ReturnType<typeof verificationFixture>;
const monthAgo = (f: Fixture) => new Date(f.clock.now().getTime() - 30 * 24 * 60 * 60 * 1000);

/** Submits every Level 1 item for the fixture's provider. */
export async function enrolled(f: Fixture): Promise<void> {
  await f.documents.saveNid(f.id, '1234567890', 'front', 'back');
  await f.documents.saveSelfie(f.id, 'selfie');
  await f.documents.savePoliceClearance(f.id, 'clearance', monthAgo(f));
  await f.documents.saveSkillProof(f.id, ['proof']);
  for (const step of ['personal', 'area', 'emergency_contact', 'code_of_conduct', 'nid']) {
    await f.changes.onStepSaved(f.id, step);
  }
}

/** Approves every item. */
export async function approveAll(f: Fixture, actor = 'verifier'): Promise<void> {
  for (const item of ITEM_TYPES) {
    await f.review.decide({ providerId: f.id, item, actor, approve: true, reason: '' });
  }
}
