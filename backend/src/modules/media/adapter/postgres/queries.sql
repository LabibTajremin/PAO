-- name: CreateObject :exec
INSERT INTO media.objects (id, owner_id, purpose, content_type, size_bytes, bucket, object_key, status, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', $8);

-- name: ObjectByID :one
SELECT id, owner_id, purpose, content_type, size_bytes, bucket, object_key, status, attached, created_at
FROM media.objects WHERE id = $1;

-- name: MarkConfirmed :exec
UPDATE media.objects SET status = 'confirmed', confirmed_at = $2 WHERE id = $1;

-- name: MarkAttached :execrows
UPDATE media.objects SET attached = true WHERE id = $1;

-- name: DeleteObject :exec
DELETE FROM media.objects WHERE id = $1;

-- name: Orphans :many
SELECT id, owner_id, purpose, content_type, size_bytes, bucket, object_key, status, attached, created_at
FROM media.objects WHERE NOT attached AND created_at < $1 ORDER BY created_at LIMIT 500;
