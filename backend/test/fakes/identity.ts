// Fakes for the identity use cases: in-memory stores with
// a `faults` map that makes a named method fail.
import { generateKeyPairSync } from 'node:crypto';
import { TokenSigner } from '../../src/platform/auth/access-token';
import { type FakeClock } from '../../src/platform/clock/fake-clock';
import { DomainError } from '../../src/platform/errors/domain-error';
import { UuidV7Generator } from '../../src/platform/ids/id-generator';
import { type Grants } from '../../src/platform/rbac/rbac';
import { type IdentityEvent } from '../../src/modules/identity/contract';
import { type Account, type Status } from '../../src/modules/identity/domain/account';
import { type Admin, type Challenge } from '../../src/modules/identity/domain/admin';
import { type StoredCode } from '../../src/modules/identity/domain/code';
import { IdentityReasons } from '../../src/modules/identity/domain/reasons';
import { type Family } from '../../src/modules/identity/domain/session';
import {
  type IdentityRepository,
  type IdentityWriter,
} from '../../src/modules/identity/port/identity-repository';

export const boom = new Error('boom');

export class Faults {
  readonly faults = new Map<string, Error>();
  protected check(name: string): void {
    const err = this.faults.get(name);
    if (err) {
      throw err;
    }
  }
}

const missing = (reason: string) => new DomainError(reason);

export class FakeRepo extends Faults implements IdentityRepository, IdentityWriter {
  readonly accounts = new Map<string, Account>();
  readonly admins = new Map<string, Admin>();
  readonly blocked = new Set<string>();
  readonly events: IdentityEvent[] = [];
  readonly grants = new Map<string, Grants>([
    ['customer', { permissions: ['booking:create'], screens: ['C01', 'C07'] }],
    ['provider', { permissions: ['job:respond'], screens: ['M01', 'M14', 'M15', 'M28'] }],
    ['verifier', { permissions: ['verification:review'], screens: ['A05'] }],
  ]);

  constructor(private readonly clock: FakeClock) {
    super();
  }

  async accountById(id: string) {
    this.check('accountById');
    return this.accounts.get(id) ?? Promise.reject(missing(IdentityReasons.AccountNotFound));
  }
  async accountByPhone(phone: string) {
    this.check('accountByPhone');
    const found = [...this.accounts.values()].find((a) => a.phone === phone);
    return found ?? Promise.reject(missing(IdentityReasons.AccountNotFound));
  }
  async adminByEmail(email: string) {
    this.check('adminByEmail');
    const found = [...this.admins.values()].find((a) => a.email === email);
    return found ?? Promise.reject(missing(IdentityReasons.AccountNotFound));
  }
  async adminById(id: string) {
    this.check('adminById');
    return this.admins.get(id) ?? Promise.reject(missing(IdentityReasons.AccountNotFound));
  }
  async listAdmins() {
    this.check('listAdmins');
    return Promise.resolve([...this.admins.values()]);
  }
  async isPhoneBlocked(phone: string) {
    this.check('isPhoneBlocked');
    return Promise.resolve(this.blocked.has(phone));
  }
  async listRoles() {
    this.check('listRoles');
    return Promise.resolve([...this.grants.keys()].sort());
  }
  async loadGrants(role: string) {
    this.check('loadGrants');
    return Promise.resolve(this.grants.get(role) ?? { permissions: [], screens: [] });
  }
  async catalogue() {
    this.check('catalogue');
    return Promise.resolve({
      permissions: ['booking:create', 'job:respond', 'verification:review'],
      screens: ['A05', 'C01', 'C07', 'M01', 'M14', 'M15', 'M28'],
    });
  }
  async inTx<T>(fn: (tx: IdentityWriter) => Promise<T>): Promise<T> {
    this.check('inTx');
    return fn(this);
  }

  async createAccount(a: Account) {
    this.check('createAccount');
    this.accounts.set(a.id, { ...a, roles: [] });
    return Promise.resolve();
  }
  async grantRole(id: string, role: string) {
    this.check('grantRole');
    this.update(id, (a) => ({ ...a, roles: [...a.roles, role] }));
    return Promise.resolve();
  }
  async setRoles(id: string, roles: readonly string[]) {
    this.check('setRoles');
    this.update(id, (a) => ({ ...a, roles: [...roles] }));
    return Promise.resolve();
  }
  async updateStatus(id: string, status: Status) {
    this.check('updateStatus');
    this.update(id, (a) => ({ ...a, status }));
    return Promise.resolve();
  }
  async blockPhone(phone: string) {
    this.blocked.add(phone);
    this.check('blockPhone');
    return Promise.resolve();
  }
  async unblockPhone(phone: string) {
    this.blocked.delete(phone);
    this.check('unblockPhone');
    return Promise.resolve();
  }
  async anonymiseAccount(id: string) {
    this.check('anonymiseAccount');
    this.update(id, (a) => ({ ...a, phone: '', deletedAt: this.clock.now() }));
    return Promise.resolve();
  }
  async createAdminCredentials(id: string, passwordHash: string) {
    this.check('createAdminCredentials');
    const account = this.accounts.get(id)!;
    this.admins.set(id, {
      ...account,
      passwordHash,
      mustChangePassword: true,
      totpSecret: '',
      totpEnrolled: false,
      failedAttempts: 0,
      lockedUntil: null,
      active: true,
      lastLoginAt: null,
    });
    return Promise.resolve();
  }
  async saveAdmin(a: Admin) {
    this.check('saveAdmin');
    this.admins.set(a.id, a);
    return Promise.resolve();
  }
  async replaceRole(role: string, grants: Grants) {
    this.grants.set(role, { permissions: [...grants.permissions], screens: [...grants.screens] });
    this.check('replaceRole');
    return Promise.resolve();
  }
  async publish(_id: string, event: IdentityEvent) {
    this.events.push(event);
    this.check('publish');
    return Promise.resolve();
  }

  private update(id: string, fn: (a: Account) => Account): void {
    const a = this.accounts.get(id);
    if (a) {
      this.accounts.set(id, fn(a));
    }
  }
}

export class FakeCodes extends Faults {
  readonly codes = new Map<string, StoredCode>();
  async save(purpose: string, phone: string, code: StoredCode) {
    this.codes.set(`${purpose}:${phone}`, code);
    this.check('save');
    return Promise.resolve();
  }
  async get(purpose: string, phone: string) {
    const code = this.codes.get(`${purpose}:${phone}`);
    if (!code) {
      throw new DomainError(IdentityReasons.CodeExpired);
    }
    this.check('get');
    return Promise.resolve(code);
  }
  async incrementAttempts(purpose: string, phone: string) {
    const key = `${purpose}:${phone}`;
    const code = this.codes.get(key)!;
    this.codes.set(key, { ...code, attempts: code.attempts + 1 });
    this.check('incrementAttempts');
    return Promise.resolve();
  }
  async delete(purpose: string, phone: string) {
    this.codes.delete(`${purpose}:${phone}`);
    this.check('delete');
    return Promise.resolve();
  }
}

export class FakeThrottle extends Faults {
  /** `phone` or `ip:{ip}` whose window is exhausted. */
  blocked = '';
  async retryAfterMs(phone: string, ip: string | undefined) {
    this.check('retryAfterMs');
    const hit = this.blocked === phone || (ip !== undefined && this.blocked === `ip:${ip}`);
    return Promise.resolve(hit ? 42_000 : 0);
  }
}

export class FakeSessions extends Faults {
  readonly families = new Map<string, Family>();
  async save(f: Family) {
    this.check('save');
    this.families.set(f.id, f);
    return Promise.resolve();
  }
  async get(id: string) {
    this.check('get');
    const f = this.families.get(id);
    return f ?? Promise.reject(new DomainError(IdentityReasons.RefreshInvalid));
  }
  async delete(f: Family) {
    this.families.delete(f.id);
    this.check('delete');
    return Promise.resolve();
  }
  async listForAccount(accountId: string) {
    this.check('listForAccount');
    return Promise.resolve([...this.families.values()].filter((f) => f.accountId === accountId));
  }
}

export class FakeChallenges extends Faults {
  readonly items = new Map<string, Challenge>();
  async save(c: Challenge) {
    this.items.set(c.id, c);
    this.check('save');
    return Promise.resolve();
  }
  async get(id: string) {
    const c = this.items.get(id);
    return c ?? Promise.reject(new DomainError(IdentityReasons.ChallengeExpired));
  }
  async delete(id: string) {
    this.items.delete(id);
    this.check('delete');
    return Promise.resolve();
  }
}

export class FakeSms extends Faults {
  readonly last = new Map<string, string>();
  async send(phone: string, message: string) {
    this.last.set(phone, message);
    this.check('send');
    return Promise.resolve();
  }
}

export class FakeDenylist extends Faults {
  readonly denied: string[] = [];
  async deny(jti: string) {
    this.denied.push(jti);
    this.check('deny');
    return Promise.resolve();
  }
}

export class FakeRbac extends Faults {
  version_ = 0;
  constructor(private readonly repo: FakeRepo) {
    super();
  }
  async grants(roles: readonly string[]) {
    this.check('grants');
    const all = roles.map((r) => this.repo.grants.get(r) ?? { permissions: [], screens: [] });
    return Promise.resolve({
      permissions: all.flatMap((g) => g.permissions),
      screens: all.flatMap((g) => g.screens),
    });
  }
  async version() {
    this.check('version');
    return Promise.resolve(this.version_);
  }
  async bumpVersion() {
    this.version_ += 1;
    this.check('bumpVersion');
    return Promise.resolve(this.version_);
  }
}

export class FakeLevels extends Faults {
  level = 0;
  async getLevel() {
    this.check('getLevel');
    return Promise.resolve(this.level);
  }
}

export class FakeSigner extends Faults {
  private readonly signer: TokenSigner;
  constructor(clock: FakeClock) {
    super();
    const { privateKey } = generateKeyPairSync('ed25519');
    this.signer = new TokenSigner(
      { keyId: 'k1', key: privateKey, ttlMs: 15 * 60_000 },
      clock,
      new UuidV7Generator(),
    );
  }
  async sign(req: Parameters<TokenSigner['sign']>[0]) {
    this.check('sign');
    return this.signer.sign(req);
  }
}
