-- name: EnsureLevel :exec
INSERT INTO verification.levels (provider_id) VALUES ($1) ON CONFLICT DO NOTHING;

-- name: LockLevel :one
SELECT provider_id, level, level2_passed_at, blocked, service_ids, submitted_at
FROM verification.levels WHERE provider_id = $1 FOR UPDATE;

-- name: LevelByProvider :one
SELECT provider_id, level, level2_passed_at, blocked, service_ids, submitted_at
FROM verification.levels WHERE provider_id = $1;

-- name: SaveLevel :exec
UPDATE verification.levels SET level = $2, level2_passed_at = $3, blocked = $4, service_ids = $5, submitted_at = $6, updated_at = $7
WHERE provider_id = $1;

-- name: ItemsByProvider :many
SELECT item_type, status, rejection_reason, fields, submitted_at, decided_at, decided_by, expires_at
FROM verification.items WHERE provider_id = $1;

-- name: UpsertItem :exec
INSERT INTO verification.items (provider_id, item_type, status, rejection_reason, fields, submitted_at, decided_at, decided_by, expires_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
ON CONFLICT (provider_id, item_type) DO UPDATE SET status = excluded.status, rejection_reason = excluded.rejection_reason,
    fields = excluded.fields, submitted_at = excluded.submitted_at, decided_at = excluded.decided_at,
    decided_by = excluded.decided_by, expires_at = excluded.expires_at;

-- name: CurrentDocuments :many
SELECT id, item_type, kind, media_id, created_at FROM verification.documents
WHERE provider_id = $1 AND current ORDER BY created_at, id;

-- name: RetireDocuments :exec
UPDATE verification.documents SET current = false WHERE provider_id = $1 AND item_type = ANY(sqlc.arg(item_types)::text[]);

-- name: InsertDocument :exec
INSERT INTO verification.documents (id, provider_id, item_type, kind, media_id, created_at) VALUES ($1, $2, $3, $4, $5, $6);

-- name: NIDByProvider :one
SELECT nid_ciphertext, nid_hash FROM verification.nid_records WHERE provider_id = $1;

-- name: UpsertNID :exec
INSERT INTO verification.nid_records (provider_id, nid_ciphertext, nid_hash, updated_at) VALUES ($1, $2, $3, $4)
ON CONFLICT (provider_id) DO UPDATE SET nid_ciphertext = excluded.nid_ciphertext, nid_hash = excluded.nid_hash, updated_at = excluded.updated_at;

-- name: NIDBlocked :one
SELECT EXISTS (SELECT 1 FROM verification.blocked_nids WHERE nid_hash = $1);

-- name: BlockNID :exec
INSERT INTO verification.blocked_nids (nid_hash, reason)
SELECT nid_hash, sqlc.arg(reason) FROM verification.nid_records WHERE provider_id = sqlc.arg(provider_id)
ON CONFLICT DO NOTHING;

-- name: SessionsByProvider :many
SELECT id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes, visit_lat, visit_lng,
    photo_media_ids, decided_by, decided_at, created_at
FROM verification.level2_sessions WHERE provider_id = $1 ORDER BY created_at, id;

-- name: SessionByID :one
SELECT id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes, visit_lat, visit_lng,
    photo_media_ids, decided_by, decided_at, created_at
FROM verification.level2_sessions WHERE id = $1;

-- name: ListSessions :many
SELECT id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes, visit_lat, visit_lng,
    photo_media_ids, decided_by, decided_at, created_at
FROM verification.level2_sessions
WHERE (sqlc.narg(provider_id)::uuid IS NULL OR provider_id = sqlc.narg(provider_id))
  AND (sqlc.narg(status)::text IS NULL OR status = sqlc.narg(status))
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (created_at, id) < (sqlc.narg(before_at), sqlc.arg(before_id)::uuid))
ORDER BY created_at DESC, id DESC LIMIT sqlc.arg(max_rows);

-- name: UpsertSession :exec
INSERT INTO verification.level2_sessions (id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes,
    visit_lat, visit_lng, photo_media_ids, decided_by, decided_at, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
ON CONFLICT (id) DO UPDATE SET status = excluded.status, result = excluded.result, checklist = excluded.checklist,
    notes = excluded.notes, visit_lat = excluded.visit_lat, visit_lng = excluded.visit_lng,
    photo_media_ids = excluded.photo_media_ids, decided_by = excluded.decided_by, decided_at = excluded.decided_at;

-- name: Levels :many
SELECT provider_id, level FROM verification.levels WHERE provider_id = ANY(sqlc.arg(ids)::uuid[]);

-- name: Queue :many
SELECT l.provider_id, l.submitted_at::timestamptz AS submitted_at, l.service_ids,
    array_agg(i.item_type ORDER BY i.item_type)::text[] AS pending_items
FROM verification.levels l
JOIN verification.items i ON i.provider_id = l.provider_id AND i.status = 'pending'
WHERE l.submitted_at IS NOT NULL
  AND (sqlc.narg(service_id)::uuid IS NULL OR sqlc.narg(service_id) = ANY(l.service_ids))
  AND (sqlc.narg(after_at)::timestamptz IS NULL OR (l.submitted_at, l.provider_id) > (sqlc.narg(after_at), sqlc.arg(after_id)::uuid))
GROUP BY l.provider_id, l.submitted_at, l.service_ids
HAVING sqlc.narg(item_type)::text IS NULL OR sqlc.narg(item_type) = ANY(array_agg(i.item_type))
ORDER BY l.submitted_at, l.provider_id LIMIT sqlc.arg(max_rows);

-- name: ExpiredBy :many
SELECT DISTINCT provider_id FROM verification.items WHERE status = 'approved' AND expires_at <= $1;

-- name: ExpiringBetween :many
SELECT provider_id, item_type, expires_at::timestamptz AS expires_at FROM verification.items
WHERE status = 'approved' AND expires_at > sqlc.arg(after_at) AND expires_at <= sqlc.arg(until_at) ORDER BY expires_at;

-- name: RecordReminder :execrows
INSERT INTO verification.reminders_sent (provider_id, item_type, expires_at, days_before, sent_at) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT DO NOTHING;

-- name: CountPendingReviews :one
SELECT count(DISTINCT l.provider_id) FROM verification.levels l
JOIN verification.items i ON i.provider_id = l.provider_id AND i.status = 'pending'
WHERE l.submitted_at IS NOT NULL;
