/** Roles seeded by the identity migration (docs/build/02-architecture.md §6). */
export const Role = {
  Customer: 'customer',
  Provider: 'provider',
  Verifier: 'verifier',
  CatalogManager: 'catalog_manager',
  SupportAgent: 'support_agent',
  SuperAdmin: 'super_admin',
} as const;

/** A named set of permissions (docs/build/02-architecture.md §6). */
export type Role = (typeof Role)[keyof typeof Role];

/** Account statuses of the PRD §6.4 lifecycle. */
export const AccountStatus = {
  Pending: 'pending',
  Active: 'active',
  Suspended: 'suspended',
  Banned: 'banned',
} as const;

/** The PRD §6.4 lifecycle: Pending → Active → Suspended → Banned. */
export type AccountStatus = (typeof AccountStatus)[keyof typeof AccountStatus];

/** Why a one-time code was sent, so codes cannot be replayed across flows. */
export const CodePurpose = {
  Login: 'login',
  DeleteAccount: 'delete_account',
  EmergencyContact: 'emergency_contact',
} as const;

/** Why a one-time code was sent, so codes cannot be replayed across flows. */
export type CodePurpose = (typeof CodePurpose)[keyof typeof CodePurpose];

/** The identity record shared by a person's customer and provider roles. */
export interface Account {
  readonly id: string;
  /** Empty when the account signs in by email only. */
  readonly phone: string;
  /** Empty when the account signs in by phone only. */
  readonly email: string;
  readonly roles: readonly Role[];
  readonly status: AccountStatus;
  readonly createdAt: Date;
}

/** Describes an admin status change. */
export interface SetAccountStatusInput {
  readonly accountId: string;
  readonly status: AccountStatus;
  readonly reason: string;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}
