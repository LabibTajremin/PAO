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

-- name: AddStatsProvider :exec
INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ($1, 'active', 0) ON CONFLICT DO NOTHING;

-- name: SetStatsLevel :exec
INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ($1, 'active', $2)
ON CONFLICT (provider_id) DO UPDATE SET level = EXCLUDED.level;

-- name: SetStatsStatus :exec
INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ($1, $2, 0)
ON CONFLICT (provider_id) DO UPDATE SET status = EXCLUDED.status;

-- name: DeleteStatsProvider :exec
DELETE FROM admin.stats_providers WHERE provider_id = $1;

-- name: BumpBookings :exec
INSERT INTO admin.stats_bookings_daily (day, requested, completed) VALUES ($1, $2, $3)
ON CONFLICT (day) DO UPDATE SET requested = admin.stats_bookings_daily.requested + EXCLUDED.requested,
    completed = admin.stats_bookings_daily.completed + EXCLUDED.completed;

-- An active provider without Level 1 is still pending verification (PRD §6.4).
-- name: ProvidersByStatus :many
SELECT (CASE WHEN status = 'active' AND level = 0 THEN 'pending' ELSE status END)::text AS status, count(*) AS n
FROM admin.stats_providers GROUP BY 1;

-- name: ProvidersByLevel :many
SELECT level, count(*) AS n FROM admin.stats_providers GROUP BY level;

-- name: BookingsSince :many
SELECT day, requested, completed FROM admin.stats_bookings_daily WHERE day >= $1 ORDER BY day;

-- name: CountOpenComplaints :one
SELECT count(*) FROM admin.complaints WHERE status <> 'resolved';

-- name: CountComplaintsAgainst :one
SELECT count(*) FROM admin.complaints WHERE against_id = $1;

-- name: ComplaintsInvolving :many
SELECT * FROM admin.complaints WHERE reporter_id = $1 OR against_id = $1 ORDER BY created_at DESC, id DESC LIMIT $2;
