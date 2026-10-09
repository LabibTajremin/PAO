-- name: EnsureProvider :exec
INSERT INTO provider.providers (id, phone, created_at, updated_at) VALUES ($1, $2, $3, $3)
ON CONFLICT (id) DO NOTHING;

-- name: ProviderByID :one
SELECT id, phone, full_name, date_of_birth, gender, present_address, permanent_address, bio, photo_media_id,
    experience_years, language, COALESCE(ST_Y(home_base::geometry), 0)::float8 AS home_lat, COALESCE(ST_X(home_base::geometry), 0)::float8 AS home_lng,
    (home_base IS NOT NULL)::bool AS has_home_base, working_radius_m, emergency_name, emergency_relation, emergency_phone,
    emergency_verified_at, coc_version, coc_accepted_at, steps_done, submitted_at, account_status, level,
    rating_avg, rating_count, completed_jobs, flagged_for_review, flag_reason, created_at,
    COALESCE((SELECT array_agg(s.service_id ORDER BY s.service_id) FROM provider.provider_services s WHERE s.provider_id = p.id), '{}')::uuid[] AS service_ids
FROM provider.providers p WHERE id = $1;

-- name: SaveProfile :exec
UPDATE provider.providers SET full_name = sqlc.arg(full_name), date_of_birth = sqlc.arg(date_of_birth), gender = sqlc.narg(gender),
    present_address = sqlc.arg(present_address), permanent_address = sqlc.arg(permanent_address), bio = sqlc.arg(bio),
    photo_media_id = sqlc.narg(photo_media_id), experience_years = sqlc.arg(experience_years), language = sqlc.arg(language),
    home_base = CASE WHEN sqlc.arg(has_home_base)::bool
        THEN ST_SetSRID(ST_MakePoint(sqlc.arg(home_lng)::float8, sqlc.arg(home_lat)::float8), 4326)::geography END,
    working_radius_m = sqlc.arg(working_radius_m), emergency_name = sqlc.arg(emergency_name),
    emergency_relation = sqlc.arg(emergency_relation), emergency_phone = sqlc.arg(emergency_phone),
    emergency_verified_at = sqlc.narg(emergency_verified_at), coc_version = sqlc.arg(coc_version),
    coc_accepted_at = sqlc.narg(coc_accepted_at), steps_done = sqlc.arg(steps_done), submitted_at = sqlc.narg(submitted_at),
    updated_at = sqlc.arg(updated_at)
WHERE id = sqlc.arg(id);

-- name: ClearServices :exec
DELETE FROM provider.provider_services WHERE provider_id = $1;

-- name: AddService :exec
INSERT INTO provider.provider_services (provider_id, service_id) VALUES ($1, $2);

-- name: Candidates :many
SELECT id, full_name, photo_media_id, gender, level, rating_avg, rating_count, completed_jobs, working_radius_m
FROM provider.providers WHERE id = ANY(sqlc.arg(ids)::uuid[]) AND account_status = 'active' AND level >= sqlc.arg(min_level);

-- name: SetLevel :exec
UPDATE provider.providers SET level = $2 WHERE id = $1;

-- name: SetAccountStatus :exec
UPDATE provider.providers SET account_status = $2 WHERE id = $1;

-- name: SetRating :one
UPDATE provider.providers SET rating_avg = $2, rating_count = $3 WHERE id = $1 RETURNING completed_jobs;

-- name: AddCompletedJob :exec
UPDATE provider.providers SET completed_jobs = completed_jobs + 1 WHERE id = $1;

-- name: Flag :execrows
UPDATE provider.providers SET flagged_for_review = true, flag_reason = $2 WHERE id = $1 AND NOT flagged_for_review;

-- name: AddCancellation :exec
INSERT INTO provider.cancellations (booking_id, provider_id, at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING;

-- name: CountCancellations :one
SELECT count(*) FROM provider.cancellations WHERE provider_id = $1 AND at > $2;

-- name: DeleteProvider :exec
DELETE FROM provider.providers WHERE id = $1;

-- An active provider without Level 1 is listed as pending verification (PRD §6.4).
-- name: SearchProviders :many
SELECT p.id, p.full_name, p.phone,
    (CASE WHEN p.account_status = 'active' AND p.level = 0 THEN 'pending' ELSE p.account_status END)::text AS status,
    p.level, p.rating_avg, p.rating_count, p.completed_jobs, p.flagged_for_review, p.flag_reason, p.created_at,
    COALESCE(array_agg(s.service_id ORDER BY s.service_id) FILTER (WHERE s.service_id IS NOT NULL), '{}')::uuid[] AS service_ids
FROM provider.providers p
LEFT JOIN provider.provider_services s ON s.provider_id = p.id
WHERE (sqlc.narg(id)::uuid IS NULL OR p.id = sqlc.narg(id)::uuid)
  AND (sqlc.arg(pattern)::text = '' OR lower(p.full_name) LIKE sqlc.arg(pattern)::text OR p.phone LIKE sqlc.arg(pattern)::text)
  AND (sqlc.narg(status)::text IS NULL
       OR (CASE WHEN p.account_status = 'active' AND p.level = 0 THEN 'pending' ELSE p.account_status END) = sqlc.narg(status)::text)
  AND (sqlc.narg(level)::int IS NULL OR p.level = sqlc.narg(level)::int)
  AND (sqlc.narg(flagged)::bool IS NULL OR p.flagged_for_review = sqlc.narg(flagged)::bool)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (p.created_at, p.id) < (sqlc.narg(before_at)::timestamptz, sqlc.arg(before_id)::uuid))
GROUP BY p.id
ORDER BY p.created_at DESC, p.id DESC
LIMIT sqlc.arg(max_rows);
