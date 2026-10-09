-- name: ListSettings :many
SELECT key, value, type, description, updated_at, updated_by FROM admin.settings ORDER BY key;

-- name: SettingByKey :one
SELECT key, value, type, description, updated_at, updated_by FROM admin.settings WHERE key = $1;

-- name: UpdateSetting :exec
UPDATE admin.settings SET value = $2, updated_at = $3, updated_by = $4 WHERE key = $1;

-- name: CountVerifiedComplaints :one
SELECT count(*) FROM admin.complaints WHERE against_id = $1 AND verified;
