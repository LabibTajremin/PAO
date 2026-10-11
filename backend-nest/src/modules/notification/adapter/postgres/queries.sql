-- name: InsertNotification :execrows
INSERT INTO notification.notifications (id, recipient_id, app, type, title, body, booking_id, dedupe_key, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ON CONFLICT (recipient_id, dedupe_key) DO NOTHING;

-- name: ListNotifications :many
SELECT id, type, title, body, booking_id, read_at, created_at FROM notification.notifications
WHERE recipient_id = sqlc.arg(recipient_id) AND app = sqlc.arg(app)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (created_at, id) < (sqlc.narg(before_at), sqlc.arg(before_id)::uuid))
ORDER BY created_at DESC, id DESC LIMIT sqlc.arg(max_rows);

-- name: CountUnread :one
SELECT count(*) FROM notification.notifications WHERE recipient_id = $1 AND app = $2 AND read_at IS NULL;

-- name: MarkRead :execrows
UPDATE notification.notifications SET read_at = COALESCE(read_at, $3) WHERE id = $1 AND recipient_id = $2 AND app = $4;

-- name: MarkAllRead :exec
UPDATE notification.notifications SET read_at = $3 WHERE recipient_id = $1 AND app = $2 AND read_at IS NULL;

-- name: UpsertToken :exec
INSERT INTO notification.device_tokens (token, account_id, app, platform, updated_at) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (token) DO UPDATE SET account_id = excluded.account_id, app = excluded.app, platform = excluded.platform,
    updated_at = excluded.updated_at;

-- name: TokensFor :many
SELECT token FROM notification.device_tokens WHERE account_id = $1 AND app = $2 ORDER BY updated_at DESC LIMIT 10;

-- name: DeleteToken :exec
DELETE FROM notification.device_tokens WHERE token = $1;

-- name: DeleteAccountNotifications :exec
DELETE FROM notification.notifications WHERE recipient_id = $1;

-- name: DeleteAccountTokens :exec
DELETE FROM notification.device_tokens WHERE account_id = $1;
