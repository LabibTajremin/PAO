-- name: ListSettings :many
SELECT key, value, type, description, updated_at, updated_by FROM admin.settings ORDER BY key;

-- name: SettingByKey :one
SELECT key, value, type, description, updated_at, updated_by FROM admin.settings WHERE key = $1;

-- name: UpdateSetting :exec
UPDATE admin.settings SET value = $2, updated_at = $3, updated_by = $4 WHERE key = $1;

-- name: CountVerifiedComplaints :one
SELECT count(*) FROM admin.complaints WHERE against_id = $1 AND verified;

-- name: InsertComplaint :one
INSERT INTO admin.complaints (id, booking_id, reporter_id, reporter_role, against_id, reason, description, photo_media_ids, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)
RETURNING ticket_number;

-- name: ComplaintByID :one
SELECT * FROM admin.complaints WHERE id = $1;

-- name: LockComplaint :one
SELECT * FROM admin.complaints WHERE id = $1 FOR UPDATE;

-- name: UpdateComplaint :exec
UPDATE admin.complaints
SET status = $2, assignee_id = $3, resolution = $4, verified = $5, updated_at = $6, resolved_at = $7
WHERE id = $1;

-- name: ListComplaints :many
SELECT * FROM admin.complaints
WHERE (sqlc.narg(status)::text IS NULL OR status = sqlc.narg(status)::text)
  AND (sqlc.narg(assignee_id)::uuid IS NULL OR assignee_id = sqlc.narg(assignee_id)::uuid)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (created_at, id) < (sqlc.narg(before_at)::timestamptz, sqlc.arg(before_id)::uuid))
ORDER BY created_at DESC, id DESC
LIMIT sqlc.arg(max_rows);

-- name: InsertComment :exec
INSERT INTO admin.complaint_comments (id, complaint_id, author_id, body, at) VALUES ($1, $2, $3, $4, $5);

-- name: ListComments :many
SELECT id, complaint_id, author_id, body, at FROM admin.complaint_comments WHERE complaint_id = $1 ORDER BY at, id;
