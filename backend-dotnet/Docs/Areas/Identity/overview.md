# Identity area — overview

Accounts, roles, permissions and screen permissions; phone OTP sign-in for customers and merchants, email, password and TOTP for admins; refresh-token families and the access-token denylist.

Code: `PAO.Core/Areas/Identity/`; contracts: `PAO.Lib/Areas/Identity/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IIdentitySharedService` | The only way other areas reach Identity (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetAccount` | Returns an account by id, or throws `identity.account_not_found`. |
| `HasRole` | Reports whether the account currently holds the role. |
| `SetAccountStatus` | Suspends, bans or reinstates an account. Banning blocks the phone number, revokes every session and publishes AccountStatusChanged (PRD §6.4). |
| `SendPhoneCode` | Sends a one-time code to a phone that is not the caller's own account, such as a merchant's emergency contact (PRD §6.2 item 6). |
| `CheckPhoneCode` | Verifies a code sent by <see cref="SendPhoneCode"/>. |
