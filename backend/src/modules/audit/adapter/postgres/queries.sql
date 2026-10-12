-- name: AppendEntry :exec
INSERT INTO audit.entries (id, at, actor_id, actor_role, action, subject_type, subject_id, reason, before, after, event_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (event_id) DO NOTHING;

-- name: List :many
SELECT id, at, actor_id, actor_role, action, subject_type, subject_id, reason, before, after
FROM audit.entries
WHERE (sqlc.narg(actor_id)::uuid IS NULL OR actor_id = sqlc.narg(actor_id))
  AND (sqlc.narg(action)::text IS NULL OR action = sqlc.narg(action))
  AND (sqlc.narg(subject_type)::text IS NULL OR subject_type = sqlc.narg(subject_type))
  AND (sqlc.narg(subject_id)::text IS NULL OR subject_id = sqlc.narg(subject_id))
  AND (sqlc.narg(from_at)::timestamptz IS NULL OR at >= sqlc.narg(from_at))
  AND (sqlc.narg(to_at)::timestamptz IS NULL OR at <= sqlc.narg(to_at))
  AND (sqlc.narg(cursor_at)::timestamptz IS NULL OR (at, id) < (sqlc.narg(cursor_at), sqlc.narg(cursor_id)::uuid))
ORDER BY at DESC, id DESC
LIMIT sqlc.arg(page_size);
