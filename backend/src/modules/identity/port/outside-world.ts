import { type TokenSigner } from '../../../platform/auth/access-token';
import { type RbacChecker } from '../../../platform/rbac/rbac';
import { type Denylist } from '../../../platform/redis/denylist';

/** Delivers text messages through the configured gateway (D10). */
export interface SmsSender {
  send(phone: string, message: string): Promise<void>;
}

/** Injection token for the {@link SmsSender}. */
export const SMS_SENDER = Symbol('SmsSender');

/** Asks verification for a provider's level, for the provider gate (PRD §8.5). */
export interface LevelReader {
  getLevel(providerId: string): Promise<number>;
}

/** Injection token for the {@link LevelReader}. */
export const LEVEL_READER = Symbol('LevelReader');

// The platform services identity uses, narrowed to what it calls so specs can fake them.

/** Issues access tokens. */
export type Signer = Pick<TokenSigner, 'sign'>;
/** Revokes live access tokens. */
export type Revoker = Pick<Denylist, 'deny'>;
/** Reads and invalidates the RBAC cache. */
export type Permissions = Pick<RbacChecker, 'grants' | 'version' | 'bumpVersion'>;
