import { type Grants } from '../../../platform/rbac/rbac';
import { type IdentityEvent } from '../contract';
import { type Account, type Status } from '../domain/account';
import { type Admin } from '../domain/admin';

/** Reads identity data and opens transactions. Missing accounts throw AccountNotFound. */
export interface IdentityRepository {
  accountById(id: string): Promise<Account>;
  accountByPhone(phone: string): Promise<Account>;
  adminByEmail(email: string): Promise<Admin>;
  adminById(id: string): Promise<Admin>;
  listAdmins(): Promise<Admin[]>;
  isPhoneBlocked(phone: string): Promise<boolean>;
  listRoles(): Promise<string[]>;
  loadGrants(role: string): Promise<Grants>;
  /** Every known permission and screen id. */
  catalogue(): Promise<{ permissions: string[]; screens: string[] }>;
  inTx<T>(fn: (tx: IdentityWriter) => Promise<T>): Promise<T>;
}

/** Writes inside one transaction; `publish` adds to the identity outbox. */
export interface IdentityWriter {
  createAccount(a: Account): Promise<void>;
  grantRole(accountId: string, role: string): Promise<void>;
  setRoles(accountId: string, roles: readonly string[]): Promise<void>;
  updateStatus(accountId: string, status: Status): Promise<void>;
  blockPhone(phone: string, reason: string): Promise<void>;
  unblockPhone(phone: string): Promise<void>;
  anonymiseAccount(accountId: string): Promise<void>;
  createAdminCredentials(accountId: string, passwordHash: string): Promise<void>;
  saveAdmin(a: Admin): Promise<void>;
  replaceRole(role: string, grants: Grants): Promise<void>;
  publish(aggregateId: string, event: IdentityEvent): Promise<void>;
}

/** Injection token for the {@link IdentityRepository}. */
export const IDENTITY_REPOSITORY = Symbol('IdentityRepository');
