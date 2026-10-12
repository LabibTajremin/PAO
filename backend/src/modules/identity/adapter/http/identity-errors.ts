import {
  ApiError,
  FORBIDDEN,
  NOT_FOUND,
  rateLimited,
  UNAUTHENTICATED,
  VALIDATION_FAILED,
} from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { ADMIN_LOCKOUT_MS } from '../../domain/admin';
import { CODE_TTL_MS } from '../../domain/code';
import { IdentityReasons as R } from '../../domain/reasons';

const signInAgain = new ApiError(401, 'REFRESH_TOKEN_INVALID', 'Sign in again.');

/** Identity's domain reasons as API errors, as the Go API answered them. */
export const identityErrors: ErrorMap = {
  [R.InvalidPhone]: VALIDATION_FAILED.withDetails({ field: 'phone' }),
  [R.AccountNotFound]: NOT_FOUND,
  [R.AccountBanned]: new ApiError(403, 'ACCOUNT_BANNED', 'This account is banned.'),
  [R.AccountSuspended]: new ApiError(403, 'ACCOUNT_SUSPENDED', 'This account is suspended.'),
  [R.AccountDeleted]: UNAUTHENTICATED,
  [R.StatusChange]: new ApiError(409, 'CONFLICT', 'The account is already in that state.'),
  [R.CodeInvalid]: new ApiError(401, 'OTP_INVALID', 'The code is wrong.'),
  [R.CodeExpired]: new ApiError(401, 'OTP_EXPIRED', 'The code expired. Ask for a new one.'),
  [R.CodeLocked]: rateLimited('OTP_LOCKED', CODE_TTL_MS),
  [R.RefreshInvalid]: signInAgain,
  [R.RefreshReused]: signInAgain,
  [R.InvalidCredentials]: new ApiError(401, 'INVALID_CREDENTIALS', 'Email or password is wrong.'),
  [R.AdminLocked]: rateLimited('ACCOUNT_LOCKED', ADMIN_LOCKOUT_MS),
  [R.AdminInactive]: FORBIDDEN,
  [R.ChallengeExpired]: new ApiError(401, 'MFA_CHALLENGE_EXPIRED', 'Sign in again.'),
  [R.TotpInvalid]: new ApiError(401, 'TOTP_INVALID', 'The authenticator code is wrong.'),
  [R.EmailTaken]: new ApiError(409, 'CONFLICT', 'That email is already used.'),
  [R.RoleInvalid]: new ApiError(422, 'ROLE_INVALID', 'Unknown role, permission or screen.'),
  [R.PasswordTooWeak]: VALIDATION_FAILED.withDetails({ field: 'newPassword' }),
};
