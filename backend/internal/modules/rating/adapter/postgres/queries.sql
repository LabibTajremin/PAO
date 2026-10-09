-- name: AddReviewable :exec
INSERT INTO rating.reviewable_bookings (booking_id, customer_id, provider_id, customer_name, provider_name, service_name_en,
    service_name_bn, completed_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT DO NOTHING;

-- name: ReviewableByID :one
SELECT booking_id, customer_id, provider_id, customer_name, provider_name, service_name_en, service_name_bn, completed_at
FROM rating.reviewable_bookings WHERE booking_id = $1;

-- name: InsertReview :exec
INSERT INTO rating.reviews (id, booking_id, author_id, author_role, author_name, subject_id, stars, tags, comment,
    service_name_en, service_name_bn, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);

-- name: AddToAggregate :one
INSERT INTO rating.aggregates (subject_id, subject_role, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5)
VALUES (sqlc.arg(subject_id), sqlc.arg(subject_role), 1, sqlc.arg(stars)::int,
    (sqlc.arg(stars)::int = 1)::int, (sqlc.arg(stars)::int = 2)::int, (sqlc.arg(stars)::int = 3)::int, (sqlc.arg(stars)::int = 4)::int, (sqlc.arg(stars)::int = 5)::int)
ON CONFLICT (subject_id, subject_role) DO UPDATE SET review_count = rating.aggregates.review_count + 1,
    star_sum = rating.aggregates.star_sum + excluded.star_sum, stars_1 = rating.aggregates.stars_1 + excluded.stars_1,
    stars_2 = rating.aggregates.stars_2 + excluded.stars_2, stars_3 = rating.aggregates.stars_3 + excluded.stars_3,
    stars_4 = rating.aggregates.stars_4 + excluded.stars_4, stars_5 = rating.aggregates.stars_5 + excluded.stars_5
RETURNING subject_id, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5;

-- name: Aggregates :many
SELECT subject_id, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5
FROM rating.aggregates WHERE subject_role = sqlc.arg(subject_role) AND subject_id = ANY(sqlc.arg(ids)::uuid[]);

-- name: Reviews :many
SELECT id, booking_id, author_id, author_role, author_name, subject_id, stars, tags, comment, service_name_en, service_name_bn, created_at
FROM rating.reviews
WHERE subject_id = sqlc.arg(subject_id) AND author_role = sqlc.arg(author_role)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (created_at, id) < (sqlc.narg(before_at), sqlc.arg(before_id)::uuid))
ORDER BY created_at DESC, id DESC LIMIT sqlc.arg(max_rows);
