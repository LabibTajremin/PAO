import { type Account, type CodePurpose, type Role, type SetAccountStatusInput } from './dto';

/**
 * What other modules may ask of identity, the only identity surface they may use
 * (PRD §9.3 rule 1).
 */
export interface IdentityService {
  /** Returns an account by id, or throws `IdentityErrors.AccountNotFound`. */
  getAccount(accountId: string): Promise<Account>;
  /** Reports whether the account currently holds the role. */
  hasRole(accountId: string, role: Role): Promise<boolean>;
  /**
   * Suspends, bans or reinstates an account. Banning blocks the phone number, revokes
   * every session and publishes AccountStatusChanged (PRD §6.4).
   */
  setAccountStatus(input: SetAccountStatusInput): Promise<Account>;
  /**
   * Sends a one-time code to a phone that is not the caller's own account, such as a
   * provider's emergency contact (PRD §6.2 item 6).
   */
  sendPhoneCode(phone: string, purpose: CodePurpose): Promise<void>;
  /** Verifies a code sent by {@link IdentityService.sendPhoneCode}. */
  checkPhoneCode(phone: string, purpose: CodePurpose, code: string): Promise<void>;
}

/** Injection token for the {@link IdentityService}. */
export const IDENTITY_SERVICE = Symbol('IdentityService');
