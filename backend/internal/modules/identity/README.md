# identity

Sign-in for customers and providers is phone + OTP; admins use email + password + TOTP.
Sessions are refresh-token families in Redis; access tokens are 15-minute EdDSA JWTs.
The repository also serves the RBAC source (`LoadGrants`) behind the Redis grant cache.

Accounts, phone OTP sign-in, admin email + password + TOTP, sessions (JWT access + rotating refresh in Redis), roles, permissions and screen permissions.

## Contract (`contract/service.go`, `IdentityService`)

- `GetAccount`
- `HasRole`
- `SetAccountStatus`
- `SendPhoneCode`
- `CheckPhoneCode`

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
