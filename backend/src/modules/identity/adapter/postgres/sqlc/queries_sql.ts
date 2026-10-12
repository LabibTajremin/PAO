import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const accountByIDQuery = `-- name: AccountByID :one
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles
FROM identity.accounts a LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE a.id = $1
GROUP BY a.id`;

export interface AccountByIDArgs {
    id: string;
}

export interface AccountByIDRow {
    id: string;
    phone: string | null;
    email: string | null;
    name: string;
    status: string;
    createdAt: Date;
    deletedAt: Date | null;
    roles: string[];
}

export async function accountByID(client: Client, args: AccountByIDArgs): Promise<AccountByIDRow | null> {
    const result = await client.query({
        text: accountByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        phone: row[1],
        email: row[2],
        name: row[3],
        status: row[4],
        createdAt: row[5],
        deletedAt: row[6],
        roles: row[7]
    };
}

export const accountByPhoneQuery = `-- name: AccountByPhone :one
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles
FROM identity.accounts a LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE a.phone = $1
GROUP BY a.id`;

export interface AccountByPhoneArgs {
    phone: string | null;
}

export interface AccountByPhoneRow {
    id: string;
    phone: string | null;
    email: string | null;
    name: string;
    status: string;
    createdAt: Date;
    deletedAt: Date | null;
    roles: string[];
}

export async function accountByPhone(client: Client, args: AccountByPhoneArgs): Promise<AccountByPhoneRow | null> {
    const result = await client.query({
        text: accountByPhoneQuery,
        values: [args.phone],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        phone: row[1],
        email: row[2],
        name: row[3],
        status: row[4],
        createdAt: row[5],
        deletedAt: row[6],
        roles: row[7]
    };
}

export const accountByEmailQuery = `-- name: AccountByEmail :one
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles
FROM identity.accounts a LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE lower(a.email) = lower($1)
GROUP BY a.id`;

export interface AccountByEmailArgs {
    lower: string;
}

export interface AccountByEmailRow {
    id: string;
    phone: string | null;
    email: string | null;
    name: string;
    status: string;
    createdAt: Date;
    deletedAt: Date | null;
    roles: string[];
}

export async function accountByEmail(client: Client, args: AccountByEmailArgs): Promise<AccountByEmailRow | null> {
    const result = await client.query({
        text: accountByEmailQuery,
        values: [args.lower],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        phone: row[1],
        email: row[2],
        name: row[3],
        status: row[4],
        createdAt: row[5],
        deletedAt: row[6],
        roles: row[7]
    };
}

export const createAccountQuery = `-- name: CreateAccount :exec
INSERT INTO identity.accounts (id, phone, email, name, status, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $6)`;

export interface CreateAccountArgs {
    id: string;
    phone: string | null;
    email: string | null;
    name: string;
    status: string;
    createdAt: Date;
}

export async function createAccount(client: Client, args: CreateAccountArgs): Promise<void> {
    await client.query({
        text: createAccountQuery,
        values: [args.id, args.phone, args.email, args.name, args.status, args.createdAt],
        rowMode: "array"
    });
}

export const grantRoleQuery = `-- name: GrantRole :exec
INSERT INTO identity.account_roles (account_id, role, granted_at) VALUES ($1, $2, $3)
ON CONFLICT DO NOTHING`;

export interface GrantRoleArgs {
    accountId: string;
    role: string;
    grantedAt: Date;
}

export async function grantRole(client: Client, args: GrantRoleArgs): Promise<void> {
    await client.query({
        text: grantRoleQuery,
        values: [args.accountId, args.role, args.grantedAt],
        rowMode: "array"
    });
}

export const revokeRolesQuery = `-- name: RevokeRoles :exec
DELETE FROM identity.account_roles WHERE account_id = $1`;

export interface RevokeRolesArgs {
    accountId: string;
}

export async function revokeRoles(client: Client, args: RevokeRolesArgs): Promise<void> {
    await client.query({
        text: revokeRolesQuery,
        values: [args.accountId],
        rowMode: "array"
    });
}

export const updateStatusQuery = `-- name: UpdateStatus :exec
UPDATE identity.accounts SET status = $2, updated_at = $3 WHERE id = $1`;

export interface UpdateStatusArgs {
    id: string;
    status: string;
    updatedAt: Date;
}

export async function updateStatus(client: Client, args: UpdateStatusArgs): Promise<void> {
    await client.query({
        text: updateStatusQuery,
        values: [args.id, args.status, args.updatedAt],
        rowMode: "array"
    });
}

export const anonymiseAccountQuery = `-- name: AnonymiseAccount :exec
UPDATE identity.accounts SET phone = NULL, email = NULL, name = '', deleted_at = $2, updated_at = $2 WHERE id = $1`;

export interface AnonymiseAccountArgs {
    id: string;
    deletedAt: Date | null;
}

export async function anonymiseAccount(client: Client, args: AnonymiseAccountArgs): Promise<void> {
    await client.query({
        text: anonymiseAccountQuery,
        values: [args.id, args.deletedAt],
        rowMode: "array"
    });
}

export const blockPhoneQuery = `-- name: BlockPhone :exec
INSERT INTO identity.blocked_phones (phone, reason, blocked_at) VALUES ($1, $2, $3)
ON CONFLICT (phone) DO NOTHING`;

export interface BlockPhoneArgs {
    phone: string;
    reason: string;
    blockedAt: Date;
}

export async function blockPhone(client: Client, args: BlockPhoneArgs): Promise<void> {
    await client.query({
        text: blockPhoneQuery,
        values: [args.phone, args.reason, args.blockedAt],
        rowMode: "array"
    });
}

export const unblockPhoneQuery = `-- name: UnblockPhone :exec
DELETE FROM identity.blocked_phones WHERE phone = $1`;

export interface UnblockPhoneArgs {
    phone: string;
}

export async function unblockPhone(client: Client, args: UnblockPhoneArgs): Promise<void> {
    await client.query({
        text: unblockPhoneQuery,
        values: [args.phone],
        rowMode: "array"
    });
}

export const isPhoneBlockedQuery = `-- name: IsPhoneBlocked :one
SELECT EXISTS (SELECT 1 FROM identity.blocked_phones WHERE phone = $1)`;

export interface IsPhoneBlockedArgs {
    phone: string;
}

export interface IsPhoneBlockedRow {
    exists: boolean;
}

export async function isPhoneBlocked(client: Client, args: IsPhoneBlockedArgs): Promise<IsPhoneBlockedRow | null> {
    const result = await client.query({
        text: isPhoneBlockedQuery,
        values: [args.phone],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        exists: row[0]
    };
}

export const adminCredentialsQuery = `-- name: AdminCredentials :one
SELECT account_id, password_hash, must_change_password, totp_secret_enc, totp_enrolled,
       failed_attempts, locked_until, active, last_login_at
FROM identity.admin_credentials WHERE account_id = $1`;

export interface AdminCredentialsArgs {
    accountId: string;
}

export interface AdminCredentialsRow {
    accountId: string;
    passwordHash: string;
    mustChangePassword: boolean;
    totpSecretEnc: Buffer | null;
    totpEnrolled: boolean;
    failedAttempts: number;
    lockedUntil: Date | null;
    active: boolean;
    lastLoginAt: Date | null;
}

export async function adminCredentials(client: Client, args: AdminCredentialsArgs): Promise<AdminCredentialsRow | null> {
    const result = await client.query({
        text: adminCredentialsQuery,
        values: [args.accountId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        accountId: row[0],
        passwordHash: row[1],
        mustChangePassword: row[2],
        totpSecretEnc: row[3],
        totpEnrolled: row[4],
        failedAttempts: row[5],
        lockedUntil: row[6],
        active: row[7],
        lastLoginAt: row[8]
    };
}

export const createAdminCredentialsQuery = `-- name: CreateAdminCredentials :exec
INSERT INTO identity.admin_credentials (account_id, password_hash, must_change_password)
VALUES ($1, $2, true)`;

export interface CreateAdminCredentialsArgs {
    accountId: string;
    passwordHash: string;
}

export async function createAdminCredentials(client: Client, args: CreateAdminCredentialsArgs): Promise<void> {
    await client.query({
        text: createAdminCredentialsQuery,
        values: [args.accountId, args.passwordHash],
        rowMode: "array"
    });
}

export const updateAdminCredentialsQuery = `-- name: UpdateAdminCredentials :exec
UPDATE identity.admin_credentials
SET password_hash = $2, must_change_password = $3, totp_secret_enc = $4, totp_enrolled = $5,
    failed_attempts = $6, locked_until = $7, active = $8, last_login_at = $9
WHERE account_id = $1`;

export interface UpdateAdminCredentialsArgs {
    accountId: string;
    passwordHash: string;
    mustChangePassword: boolean;
    totpSecretEnc: Buffer | null;
    totpEnrolled: boolean;
    failedAttempts: number;
    lockedUntil: Date | null;
    active: boolean;
    lastLoginAt: Date | null;
}

export async function updateAdminCredentials(client: Client, args: UpdateAdminCredentialsArgs): Promise<void> {
    await client.query({
        text: updateAdminCredentialsQuery,
        values: [args.accountId, args.passwordHash, args.mustChangePassword, args.totpSecretEnc, args.totpEnrolled, args.failedAttempts, args.lockedUntil, args.active, args.lastLoginAt],
        rowMode: "array"
    });
}

export const listAdminsQuery = `-- name: ListAdmins :many
SELECT a.id, a.phone, a.email, a.name, a.status, a.created_at, a.deleted_at,
       coalesce(array_agg(r.role ORDER BY r.role) FILTER (WHERE r.role IS NOT NULL), '{}')::text[] AS roles,
       c.password_hash, c.must_change_password, c.totp_secret_enc, c.totp_enrolled,
       c.failed_attempts, c.locked_until, c.active, c.last_login_at
FROM identity.admin_credentials c
JOIN identity.accounts a ON a.id = c.account_id
LEFT JOIN identity.account_roles r ON r.account_id = a.id
WHERE a.deleted_at IS NULL
GROUP BY a.id, c.account_id
ORDER BY a.email`;

export interface ListAdminsRow {
    id: string;
    phone: string | null;
    email: string | null;
    name: string;
    status: string;
    createdAt: Date;
    deletedAt: Date | null;
    roles: string[];
    passwordHash: string;
    mustChangePassword: boolean;
    totpSecretEnc: Buffer | null;
    totpEnrolled: boolean;
    failedAttempts: number;
    lockedUntil: Date | null;
    active: boolean;
    lastLoginAt: Date | null;
}

export async function listAdmins(client: Client): Promise<ListAdminsRow[]> {
    const result = await client.query({
        text: listAdminsQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            phone: row[1],
            email: row[2],
            name: row[3],
            status: row[4],
            createdAt: row[5],
            deletedAt: row[6],
            roles: row[7],
            passwordHash: row[8],
            mustChangePassword: row[9],
            totpSecretEnc: row[10],
            totpEnrolled: row[11],
            failedAttempts: row[12],
            lockedUntil: row[13],
            active: row[14],
            lastLoginAt: row[15]
        };
    });
}

export const listRolesQuery = `-- name: ListRoles :many
SELECT name FROM identity.roles ORDER BY name`;

export interface ListRolesRow {
    name: string;
}

export async function listRoles(client: Client): Promise<ListRolesRow[]> {
    const result = await client.query({
        text: listRolesQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            name: row[0]
        };
    });
}

export const rolePermissionsQuery = `-- name: RolePermissions :many
SELECT permission FROM identity.role_permissions WHERE role = $1 ORDER BY permission`;

export interface RolePermissionsArgs {
    role: string;
}

export interface RolePermissionsRow {
    permission: string;
}

export async function rolePermissions(client: Client, args: RolePermissionsArgs): Promise<RolePermissionsRow[]> {
    const result = await client.query({
        text: rolePermissionsQuery,
        values: [args.role],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            permission: row[0]
        };
    });
}

export const roleScreensQuery = `-- name: RoleScreens :many
SELECT screen_id FROM identity.role_screens WHERE role = $1 ORDER BY screen_id`;

export interface RoleScreensArgs {
    role: string;
}

export interface RoleScreensRow {
    screenId: string;
}

export async function roleScreens(client: Client, args: RoleScreensArgs): Promise<RoleScreensRow[]> {
    const result = await client.query({
        text: roleScreensQuery,
        values: [args.role],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            screenId: row[0]
        };
    });
}

export const allPermissionsQuery = `-- name: AllPermissions :many
SELECT name FROM identity.permissions ORDER BY name`;

export interface AllPermissionsRow {
    name: string;
}

export async function allPermissions(client: Client): Promise<AllPermissionsRow[]> {
    const result = await client.query({
        text: allPermissionsQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            name: row[0]
        };
    });
}

export const allScreensQuery = `-- name: AllScreens :many
SELECT id FROM identity.screens ORDER BY id`;

export interface AllScreensRow {
    id: string;
}

export async function allScreens(client: Client): Promise<AllScreensRow[]> {
    const result = await client.query({
        text: allScreensQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0]
        };
    });
}

export const clearRoleQuery = `-- name: ClearRole :exec
WITH p AS (DELETE FROM identity.role_permissions WHERE role_permissions.role = $1)
DELETE FROM identity.role_screens WHERE role_screens.role = $1`;

export interface ClearRoleArgs {
    role: string;
}

export async function clearRole(client: Client, args: ClearRoleArgs): Promise<void> {
    await client.query({
        text: clearRoleQuery,
        values: [args.role],
        rowMode: "array"
    });
}

export const addRolePermissionQuery = `-- name: AddRolePermission :exec
INSERT INTO identity.role_permissions (role, permission) VALUES ($1, $2)`;

export interface AddRolePermissionArgs {
    role: string;
    permission: string;
}

export async function addRolePermission(client: Client, args: AddRolePermissionArgs): Promise<void> {
    await client.query({
        text: addRolePermissionQuery,
        values: [args.role, args.permission],
        rowMode: "array"
    });
}

export const addRoleScreenQuery = `-- name: AddRoleScreen :exec
INSERT INTO identity.role_screens (role, screen_id) VALUES ($1, $2)`;

export interface AddRoleScreenArgs {
    role: string;
    screenId: string;
}

export async function addRoleScreen(client: Client, args: AddRoleScreenArgs): Promise<void> {
    await client.query({
        text: addRoleScreenQuery,
        values: [args.role, args.screenId],
        rowMode: "array"
    });
}

