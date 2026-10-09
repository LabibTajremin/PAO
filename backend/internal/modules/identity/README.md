# identity

Accounts, phone OTP sign-in, admin email + password + TOTP, sessions (JWT access + rotating refresh in Redis), roles, permissions and screen permissions.

## Contract (`contract/service.go`, `IdentityService`)

- `GetAccount`
- `HasRole`
- `SetAccountStatus`
- `SendPhoneCode`
- `CheckPhoneCode`
- `CreateAdminAccount`
- `UpdateAdminAccount`
- `ListAdminAccounts`
- `ListRoles`
- `UpdateRole`

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

Migrations: `backend/migrations/identity/`.
