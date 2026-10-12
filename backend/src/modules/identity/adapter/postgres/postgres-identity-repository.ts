import { Inject, Injectable } from '@nestjs/common';
import { DataCipher } from '../../../../platform/auth/data-cipher';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';
import { type Grants } from '../../../../platform/rbac/rbac';
import { type Account, type Status } from '../../domain/account';
import { type Admin } from '../../domain/admin';
import { IdentityReasons } from '../../domain/reasons';
import { type IdentityRepository, type IdentityWriter } from '../../port/identity-repository';
import { PostgresIdentityWriter } from './postgres-identity-writer';
import * as q from './sqlc/queries_sql';

/** An account row as the account queries return it. */
type AccountRow = q.AccountByIDRow;

function toAccount(r: AccountRow): Account {
  return {
    id: r.id,
    phone: r.phone ?? '',
    email: r.email ?? '',
    name: r.name,
    status: r.status as Status,
    roles: r.roles,
    createdAt: r.createdAt,
    deletedAt: r.deletedAt,
  };
}

/** The credential columns of an admin row. */
type CredentialsRow = Omit<q.AdminCredentialsRow, 'accountId'>;

function toAdmin(a: Account, c: CredentialsRow, cipher: DataCipher): Admin {
  return {
    ...a,
    passwordHash: c.passwordHash,
    mustChangePassword: c.mustChangePassword,
    totpSecret: c.totpSecretEnc === null ? '' : cipher.decrypt(c.totpSecretEnc).toString(),
    totpEnrolled: c.totpEnrolled,
    failedAttempts: c.failedAttempts,
    lockedUntil: c.lockedUntil,
    active: c.active,
    lastLoginAt: c.lastLoginAt,
  };
}

function found<T>(row: T | null): T {
  if (row === null) {
    throw new DomainError(IdentityReasons.AccountNotFound);
  }
  return row;
}

/** The identity repository on the `identity` schema. */
@Injectable()
export class PostgresIdentityRepository implements IdentityRepository {
  private readonly outbox: OutboxWriter;

  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) ids: IdGenerator,
    @Inject(DataCipher) private readonly cipher: DataCipher,
  ) {
    this.outbox = new OutboxWriter('identity', ids, clock);
  }

  async accountById(id: string): Promise<Account> {
    return toAccount(found(await q.accountByID(this.db.pool, { id })));
  }

  async accountByPhone(phone: string): Promise<Account> {
    return toAccount(found(await q.accountByPhone(this.db.pool, { phone })));
  }

  async adminByEmail(email: string): Promise<Admin> {
    const lower = email.trim().toLowerCase();
    return this.withCredentials(toAccount(found(await q.accountByEmail(this.db.pool, { lower }))));
  }

  async adminById(id: string): Promise<Admin> {
    return this.withCredentials(await this.accountById(id));
  }

  async listAdmins(): Promise<Admin[]> {
    return (await q.listAdmins(this.db.pool)).map((r) => toAdmin(toAccount(r), r, this.cipher));
  }

  async isPhoneBlocked(phone: string): Promise<boolean> {
    return (await q.isPhoneBlocked(this.db.pool, { phone }))?.exists ?? false;
  }

  async listRoles(): Promise<string[]> {
    return (await q.listRoles(this.db.pool)).map((r) => r.name);
  }

  async loadGrants(role: string): Promise<Grants> {
    const permissions = await q.rolePermissions(this.db.pool, { role });
    const screens = await q.roleScreens(this.db.pool, { role });
    return {
      permissions: permissions.map((r) => r.permission),
      screens: screens.map((r) => r.screenId),
    };
  }

  async catalogue(): Promise<{ permissions: string[]; screens: string[] }> {
    const permissions = await q.allPermissions(this.db.pool);
    const screens = await q.allScreens(this.db.pool);
    return { permissions: permissions.map((r) => r.name), screens: screens.map((r) => r.id) };
  }

  inTx<T>(fn: (tx: IdentityWriter) => Promise<T>): Promise<T> {
    return this.db.transaction((client) =>
      fn(new PostgresIdentityWriter(client, this.outbox, this.clock, this.cipher)),
    );
  }

  private async withCredentials(a: Account): Promise<Admin> {
    const credentials = found(await q.adminCredentials(this.db.pool, { accountId: a.id }));
    return toAdmin(a, credentials, this.cipher);
  }
}
