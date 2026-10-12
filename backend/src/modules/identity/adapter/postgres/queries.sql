-- name: AccountByID :one
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles
FROM identity.accounts a LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE a.id = $1
GROUP BY a.id;

-- name: AccountByPhone :one
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles
FROM identity.accounts a LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE a.phone = $1
GROUP BY a.id;

-- name: AccountByEmail :one
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles
FROM identity.accounts a LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE lower(a.email) = lower($1)
GROUP BY a.id;

-- name: CreateAccount :exec
INSERT INTO identity.accounts (id, phone, email, name, status, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $6);

-- name: GrantRole :exec
INSERT INTO identity.account_roles (account_id, role, granted_at) VALUES ($1, $2, $3)
ON CONFLICT DO NOTHING;

-- name: RevokeRoles :exec
DELETE FROM identity.account_roles WHERE account_id = $1;

-- name: UpdateStatus :exec
UPDATE identity.accounts SET status = $2, updated_at = $3 WHERE id = $1;

-- name: AnonymiseAccount :exec
UPDATE identity.accounts SET phone = NULL, email = NULL, name = '', deleted_at = $2, updated_at = $2 WHERE id = $1;

-- name: BlockPhone :exec
INSERT INTO identity.blocked_phones (phone, reason, blocked_at) VALUES ($1, $2, $3)
ON CONFLICT (phone) DO NOTHING;

-- name: UnblockPhone :exec
DELETE FROM identity.blocked_phones WHERE phone = $1;

-- name: IsPhoneBlocked :one
SELECT EXISTS (SELECT 1 FROM identity.blocked_phones WHERE phone = $1);

-- name: AdminCredentials :one
SELECT account_id, password_hash, must_change_password, totp_secret_enc, totp_enrolled,
       failed_attempts, locked_until, active, last_login_at
FROM identity.admin_credentials WHERE account_id = $1;

-- name: CreateAdminCredentials :exec
INSERT INTO identity.admin_credentials (account_id, password_hash, must_change_password)
VALUES ($1, $2, true);

-- name: UpdateAdminCredentials :exec
UPDATE identity.admin_credentials
SET password_hash = $2, must_change_password = $3, totp_secret_enc = $4, totp_enrolled = $5,
    failed_attempts = $6, locked_until = $7, active = $8, last_login_at = $9
WHERE account_id = $1;

-- name: ListAdmins :many
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles,
       c.password_hash, c.must_change_password, c.totp_secret_enc, c.totp_enrolled,
       c.failed_attempts, c.locked_until, c.active, c.last_login_at
FROM identity.admin_credentials c
JOIN identity.accounts a ON a.id = c.account_id
LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE a.deleted_at IS NULL
GROUP BY a.id, c.account_id
ORDER BY a.email;

-- name: ListRoles :many
SELECT name FROM identity.roles ORDER BY name;

-- name: RolePermissions :many
SELECT permission FROM identity.role_permissions WHERE role = $1 ORDER BY permission;

-- name: RoleScreens :many
SELECT screen_id FROM identity.role_screens WHERE role = $1 ORDER BY screen_id;

-- name: AllPermissions :many
SELECT name FROM identity.permissions ORDER BY name;

-- name: AllScreens :many
SELECT id FROM identity.screens ORDER BY id;

-- name: ClearRole :exec
WITH p AS (DELETE FROM identity.role_permissions WHERE role_permissions.role = $1)
DELETE FROM identity.role_screens WHERE role_screens.role = $1;

-- name: AddRolePermission :exec
INSERT INTO identity.role_permissions (role, permission) VALUES ($1, $2);

-- name: AddRoleScreen :exec
INSERT INTO identity.role_screens (role, screen_id) VALUES ($1, $2);
