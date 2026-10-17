import { type DataCipher } from '../../../../platform/auth/data-cipher';
import { type Clock } from '../../../../platform/clock/clock';
import { type SqlClient } from '../../../../platform/db/database';
import { type OutboxWriter } from '../../../../platform/outbox/outbox';
import { type Grants } from '../../../../platform/rbac/rbac';
import { type IdentityEvent } from '../../contract';
import { type Account, type Status } from '../../domain/account';
import { type Admin } from '../../domain/admin';
import { type IdentityWriter } from '../../port/identity-repository';
import * as q from './sqlc/queries_sql';

const orNull = (s: string): string | null => (s === '' ? null : s);

/** Identity writes on one transaction's client; TOTP secrets are stored encrypted. */
export class PostgresIdentityWriter implements IdentityWriter {
  constructor(
    private readonly tx: SqlClient,
    private readonly outbox: OutboxWriter,
    private readonly clock: Clock,
    private readonly cipher: DataCipher,
  ) {}

  createAccount(a: Account): Promise<void> {
    return q.createAccount(this.tx, {
      id: a.id,
      phone: orNull(a.phone),
      email: orNull(a.email.trim().toLowerCase()),
      name: a.name,
      status: a.status,
      createdAt: a.createdAt,
    });
  }

  grantRole(accountId: string, role: string): Promise<void> {
    return q.grantRole(this.tx, { accountId, role, grantedAt: this.clock.now() });
  }

  async setRoles(accountId: string, roles: readonly string[]): Promise<void> {
    await q.revokeRoles(this.tx, { accountId });
    for (const role of roles) {
      await this.grantRole(accountId, role);
    }
  }

  updateStatus(id: string, status: Status): Promise<void> {
    return q.updateStatus(this.tx, { id, status, updatedAt: this.clock.now() });
  }

  blockPhone(phone: string, reason: string): Promise<void> {
    return q.blockPhone(this.tx, { phone, reason, blockedAt: this.clock.now() });
  }

  unblockPhone(phone: string): Promise<void> {
    return q.unblockPhone(this.tx, { phone });
  }

  anonymiseAccount(id: string): Promise<void> {
    return q.anonymiseAccount(this.tx, { id, deletedAt: this.clock.now() });
  }

  createAdminCredentials(accountId: string, passwordHash: string): Promise<void> {
    return q.createAdminCredentials(this.tx, { accountId, passwordHash });
  }

  saveAdmin(a: Admin): Promise<void> {
    return q.updateAdminCredentials(this.tx, {
      accountId: a.id,
      passwordHash: a.passwordHash,
      mustChangePassword: a.mustChangePassword,
      totpSecretEnc: a.totpSecret === '' ? null : this.cipher.encrypt(Buffer.from(a.totpSecret)),
      totpEnrolled: a.totpEnrolled,
      failedAttempts: a.failedAttempts,
      lockedUntil: a.lockedUntil,
      active: a.active,
      lastLoginAt: a.lastLoginAt,
    });
  }

  async replaceRole(role: string, grants: Grants): Promise<void> {
    await q.clearRole(this.tx, { role });
    for (const permission of grants.permissions) {
      await q.addRolePermission(this.tx, { role, permission });
    }
    for (const screenId of grants.screens) {
      await q.addRoleScreen(this.tx, { role, screenId });
    }
  }

  publish(aggregateId: string, event: IdentityEvent): Promise<void> {
    return this.outbox.write(this.tx, aggregateId, event);
  }
}
