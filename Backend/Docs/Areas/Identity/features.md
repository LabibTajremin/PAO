# Identity area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Request | Use case |
|---|---|---|
| `RequestOtp` | `RequestOtpCommand` | Sends a 6-digit code by SMS (`login` or `delete_account`). Banned phones get no login code; resend, per-phone and per-IP windows answer 429 `RATE_LIMITED` with Retry-After. |
| `VerifyOtp` | `VerifyOtpCommand` | Checks the code (5 guesses, then `OTP_LOCKED`), creates the account on first sign-in or adds the app's role (partner app → `provider`), publishes `AccountCreated`/`RoleGranted`, opens a session. |
| `RefreshToken` | `RefreshTokenCommand` | Rotates the refresh family; presenting a rotated token revokes the family. The admin web app's cookie is rotated as a cookie. |
| `Logout` | `LogoutCommand` | Denylists the access token and ends this family, or every family of the account. |
| `AdminLogin` | `AdminLoginRequest` | Email + password; 5 wrong passwords lock out for 15 minutes. Not a command on purpose: the failure count must persist although the login is refused. Starts the TOTP challenge (enrolment secret on the first login). |
| `AdminVerifyTotp` | `AdminVerifyTotpCommand` | Completes the login; the first code confirms enrolment; 5 wrong codes drop the challenge. |
| `ChangeAdminPassword` | `ChangeAdminPasswordCommand` | Checks the current password, requires a passphrase (≥ 12, letters and another kind). |
| `GetMe` | `GetMeQuery` | The signed-in account. |
| `GetMyPermissions` | `GetMyPermissionsQuery` | Roles, permissions and screens; a merchant below Level 1 sees only M01–M14 of the partner screens (PRD §8.5). |
| `DeleteMe` | `DeleteMeCommand` | After a `delete_account` code: roles removed, data anonymised, `AccountDeleted` published, every session ended (PRD §11). |
| `AdminUsers` | `ListAdminUsersQuery`, `InviteAdminUserCommand`, `UpdateAdminUserCommand`, `EnsureSeedAdminCommand`, `CreateSuperAdminCommand` | The admin user screens (A-10), the seed's demo admins and the first production super admin (`migrate create-admin`). Updating revokes the admin's sessions. |
| `RoleEditor` | `ListRolesQuery`, `UpdateRoleCommand` | The role editor (A-10); an update bumps `rbac:version`. |
| `SetAccountStatus` | `SetAccountStatusCommand` | Suspend, ban, reinstate (A-05), for other areas through the shared service. |
