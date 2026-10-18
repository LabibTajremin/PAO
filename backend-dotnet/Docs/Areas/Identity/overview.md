# Identity area — overview

Accounts, roles, permissions and screen permissions; phone OTP sign-in for customers and merchants, email, password and TOTP for admins; refresh-token families and the access-token denylist.

Code: `PAO.Core/Areas/Identity/`; contracts, records, request and view models and the
`IdentityMappingProfile`: `PAO.Lib/Areas/Identity/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IIdentitySharedService` | The only way other areas reach Identity (`Services/Shared/`). |
| `IdentitySharedService` | Its implementation; status changes go through `SetAccountStatusCommand` so they run in a transaction. |
| `IdentityReasons` | Reason keys and `IdentityErrorMap`, their API errors. |
| `IdentityRules` | The rules and values (code length, TTLs, send windows, lockout, password strength, refresh-token format, provider gate screens). |
| `ShortLivedState` | `ICodeStore`, `ISendThrottle`, `ISessionStore`, `IChallengeStore` and their records (`StoredCode`, `Family`, `Challenge`). |
| `AccessTokens` | `IAccessTokens` (sign at the RBAC version, revoke via the denylist) and `IRbacGrants`. |
| `VerificationLevels` | `ILevelReader`; resolves `IVerificationSharedService` on first use, since Verification is ported later. |
| `PhoneCodes` | Sends and checks one-time codes per purpose. |
| `PhoneAccounts` | Finds and registers people by phone; also `AccountStatusChanger` (A-05). |
| `Sessions` | Refresh families: open, rotate with reuse detection, logout, revoke all. |
| `AdminUsers` | Invites admins and ensures the seed's demo admins. |

## Shared contract

| Method | Contract |
|---|---|
| `GetAccount` | Returns an account by id, or throws `identity.account_not_found`. |
| `HasRole` | Reports whether the account currently holds the role. |
| `SetAccountStatus` | Suspends, bans or reinstates an account. Banning blocks the phone number, revokes every session and publishes AccountStatusChanged (PRD §6.4). |
| `SendPhoneCode` | Sends a one-time code to a phone that is not the caller's own account, such as a merchant's emergency contact (PRD §6.2 item 6). No per-IP window. |
| `CheckPhoneCode` | Verifies a code sent by `SendPhoneCode`. |
