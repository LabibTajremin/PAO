# identity

Sign-in for customers and providers is phone + OTP; admins use email + password + TOTP.
Sessions are refresh-token families in Redis; access tokens are 15-minute EdDSA JWTs.
The repository also serves the RBAC source (`LoadGrants`) behind the Redis grant cache.

Accounts, phone OTP sign-in, admin email + password + TOTP, sessions (JWT access + rotating refresh in Redis), roles, permissions and screen permissions.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

Use cases live in `app/`: `PhoneCodes` (send and check one-time codes), `PhoneSignIn`,
`Sessions` with `AccessTokens` (refresh families, reuse detection, logout), `AdminSignIn`
and `AdminTotp` (password + TOTP, 15-minute lockout), `AdminUsers`, `MyAccount`,
`AccountDeletion`, `AccountStatusChanger` and `RoleEditor`. Domain rules return reasons
(`domain/reasons.ts`); use cases throw them as `DomainError`, and `adapter/http` maps
them to the API's error codes (`api/openapi.yaml`). TOTP secrets are encrypted by the Postgres adapter.

The provider gate reads levels from verification through a lazy contract
(`adapter/inproc/verification-levels.ts`). SMS goes through the console, SSL Wireless or,
with APP_ENV=test, the capture behind the platform's `SMS_CAPTURE`. `ADMIN_SEEDER` creates
the seed file's demo admins for `migrate seed`.

## Contract (`contract/identity-service.ts`, `IdentityService`, token `IDENTITY_SERVICE`)

- `getAccount`
- `hasRole`
- `setAccountStatus`
- `sendPhoneCode`
- `checkPhoneCode`

## Events published

- `AccountCreated`
- `RoleGranted`
- `AccountStatusChanged`
- `AccountDeleted`

## Events consumed

None.

## Tables (schema `identity`)

- `accounts`
- `account_roles`
- `admin_credentials`
- `blocked_phones`
- `roles`
- `permissions`
- `role_permissions`
- `screens`
- `role_screens`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/auth/*`
- `/v1/me`
- `/v1/me/permissions`
- `/v1/admin/admin-users*`, `/v1/admin/roles*` (admin users and the role editor, A-01/A-10)

Migrations: `backend/migrations/identity/`.
