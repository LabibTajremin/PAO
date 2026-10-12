import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const insertNotificationQuery = `-- name: InsertNotification :execrows
INSERT INTO notification.notifications (id, recipient_id, app, type, title, body, booking_id, dedupe_key, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ON CONFLICT (recipient_id, dedupe_key) DO NOTHING`;

export interface InsertNotificationArgs {
    id: string;
    recipientId: string;
    app: string;
    type: string;
    title: string;
    body: string;
    bookingId: string | null;
    dedupeKey: string;
    createdAt: Date;
}

export const listNotificationsQuery = `-- name: ListNotifications :many
SELECT id, type, title, body, booking_id, read_at, created_at FROM notification.notifications
WHERE recipient_id = $1 AND app = $2
  AND ($3::timestamptz IS NULL OR (created_at, id) < ($3, $4::uuid))
ORDER BY created_at DESC, id DESC LIMIT $5`;

export interface ListNotificationsArgs {
    recipientId: string;
    app: string;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface ListNotificationsRow {
    id: string;
    type: string;
    title: string;
    body: string;
    bookingId: string | null;
    readAt: Date | null;
    createdAt: Date;
}

export async function listNotifications(client: Client, args: ListNotificationsArgs): Promise<ListNotificationsRow[]> {
    const result = await client.query({
        text: listNotificationsQuery,
        values: [args.recipientId, args.app, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            type: row[1],
            title: row[2],
            body: row[3],
            bookingId: row[4],
            readAt: row[5],
            createdAt: row[6]
        };
    });
}

export const countUnreadQuery = `-- name: CountUnread :one
SELECT count(*) FROM notification.notifications WHERE recipient_id = $1 AND app = $2 AND read_at IS NULL`;

export interface CountUnreadArgs {
    recipientId: string;
    app: string;
}

export interface CountUnreadRow {
    count: string;
}

export async function countUnread(client: Client, args: CountUnreadArgs): Promise<CountUnreadRow | null> {
    const result = await client.query({
        text: countUnreadQuery,
        values: [args.recipientId, args.app],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        count: row[0]
    };
}

export const markReadQuery = `-- name: MarkRead :execrows
UPDATE notification.notifications SET read_at = COALESCE(read_at, $3) WHERE id = $1 AND recipient_id = $2 AND app = $4`;

export interface MarkReadArgs {
    id: string;
    recipientId: string;
    readAt: Date | null;
    app: string;
}

export const markAllReadQuery = `-- name: MarkAllRead :exec
UPDATE notification.notifications SET read_at = $3 WHERE recipient_id = $1 AND app = $2 AND read_at IS NULL`;

export interface MarkAllReadArgs {
    recipientId: string;
    app: string;
    readAt: Date | null;
}

export async function markAllRead(client: Client, args: MarkAllReadArgs): Promise<void> {
    await client.query({
        text: markAllReadQuery,
        values: [args.recipientId, args.app, args.readAt],
        rowMode: "array"
    });
}

export const upsertTokenQuery = `-- name: UpsertToken :exec
INSERT INTO notification.device_tokens (token, account_id, app, platform, updated_at) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (token) DO UPDATE SET account_id = excluded.account_id, app = excluded.app, platform = excluded.platform,
    updated_at = excluded.updated_at`;

export interface UpsertTokenArgs {
    token: string;
    accountId: string;
    app: string;
    platform: string;
    updatedAt: Date;
}

export async function upsertToken(client: Client, args: UpsertTokenArgs): Promise<void> {
    await client.query({
        text: upsertTokenQuery,
        values: [args.token, args.accountId, args.app, args.platform, args.updatedAt],
        rowMode: "array"
    });
}

export const tokensForQuery = `-- name: TokensFor :many
SELECT token FROM notification.device_tokens WHERE account_id = $1 AND app = $2 ORDER BY updated_at DESC LIMIT 10`;

export interface TokensForArgs {
    accountId: string;
    app: string;
}

export interface TokensForRow {
    token: string;
}

export async function tokensFor(client: Client, args: TokensForArgs): Promise<TokensForRow[]> {
    const result = await client.query({
        text: tokensForQuery,
        values: [args.accountId, args.app],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            token: row[0]
        };
    });
}

export const deleteTokenQuery = `-- name: DeleteToken :exec
DELETE FROM notification.device_tokens WHERE token = $1`;

export interface DeleteTokenArgs {
    token: string;
}

export async function deleteToken(client: Client, args: DeleteTokenArgs): Promise<void> {
    await client.query({
        text: deleteTokenQuery,
        values: [args.token],
        rowMode: "array"
    });
}

export const deleteAccountNotificationsQuery = `-- name: DeleteAccountNotifications :exec
DELETE FROM notification.notifications WHERE recipient_id = $1`;

export interface DeleteAccountNotificationsArgs {
    recipientId: string;
}

export async function deleteAccountNotifications(client: Client, args: DeleteAccountNotificationsArgs): Promise<void> {
    await client.query({
        text: deleteAccountNotificationsQuery,
        values: [args.recipientId],
        rowMode: "array"
    });
}

export const deleteAccountTokensQuery = `-- name: DeleteAccountTokens :exec
DELETE FROM notification.device_tokens WHERE account_id = $1`;

export interface DeleteAccountTokensArgs {
    accountId: string;
}

export async function deleteAccountTokens(client: Client, args: DeleteAccountTokensArgs): Promise<void> {
    await client.query({
        text: deleteAccountTokensQuery,
        values: [args.accountId],
        rowMode: "array"
    });
}

