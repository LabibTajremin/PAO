import { type DomainEvent } from '../../../platform/events/domain-event';
import { type AccountStatus, type Role } from './dto';

/** Outbox names of identity's events; stored, so they never change. */
export const IdentityEvents = {
  AccountCreated: 'identity.AccountCreated',
  RoleGranted: 'identity.RoleGranted',
  AccountStatusChanged: 'identity.AccountStatusChanged',
  AccountDeleted: 'identity.AccountDeleted',
} as const;

/** Published when a person signs in for the first time. */
export interface AccountCreated extends DomainEvent<typeof IdentityEvents.AccountCreated> {
  readonly accountId: string;
  readonly phone: string;
  readonly role: Role;
}

/**
 * Published when an existing account gains a role, e.g. a customer signing in to the
 * partner app becomes a provider (PRD §3).
 */
export interface RoleGranted extends DomainEvent<typeof IdentityEvents.RoleGranted> {
  readonly accountId: string;
  readonly role: Role;
}

/** Published on suspend, ban and reinstate. */
export interface AccountStatusChanged extends DomainEvent<
  typeof IdentityEvents.AccountStatusChanged
> {
  readonly accountId: string;
  readonly from: AccountStatus;
  readonly to: AccountStatus;
  readonly reason: string;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
  readonly roles: readonly Role[];
}

/**
 * Published after a user deletes their account; every module erases the person's data
 * when it receives it (PRD §11).
 */
export interface AccountDeleted extends DomainEvent<typeof IdentityEvents.AccountDeleted> {
  readonly accountId: string;
}

/** Any event identity publishes. */
export type IdentityEvent = AccountCreated | RoleGranted | AccountStatusChanged | AccountDeleted;
