import { type IdentityReason, IdentityReasons } from './reasons';

/** The PRD §6.4 lifecycle. */
export type Status = 'pending' | 'active' | 'suspended' | 'banned';

/** Roles of operations staff (docs/build/02-architecture.md §6). */
export const ADMIN_ROLES: readonly string[] = [
  'verifier',
  'catalog_manager',
  'support_agent',
  'super_admin',
];

/** One person's identity; customer and provider roles share it (PRD §3). */
export interface Account {
  readonly id: string;
  /** Empty for email-only accounts and after deletion. */
  readonly phone: string;
  readonly email: string;
  readonly name: string;
  readonly status: Status;
  readonly roles: readonly string[];
  readonly createdAt: Date;
  readonly deletedAt: Date | null;
}

/** Why the account may not sign in, or undefined when it may. */
export function signInRefusal(a: Account): IdentityReason | undefined {
  if (a.deletedAt !== null) {
    return IdentityReasons.AccountDeleted;
  }
  if (a.status === 'banned') {
    return IdentityReasons.AccountBanned;
  }
  return a.status === 'suspended' ? IdentityReasons.AccountSuspended : undefined;
}

/**
 * The role a sign-in through an app grants: the partner app makes the person a
 * provider, the customer app a customer (PRD §3).
 */
export function roleForApp(app: string): string {
  return app === 'partner' ? 'provider' : 'customer';
}

/**
 * Reports whether an admin may move the account to `to`: a live account may be
 * suspended, banned or reinstated, never to the status it already has.
 */
export function canChangeStatus(a: Account, to: Status): boolean {
  return a.deletedAt === null && a.status !== to && to !== 'pending';
}

/** Reports whether there is at least one role and every role is an admin role. */
export function isAdminRoleSet(roles: readonly string[]): boolean {
  return roles.length > 0 && roles.every((r) => ADMIN_ROLES.includes(r));
}
