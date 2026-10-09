-- name: InsertBooking :one
INSERT INTO booking.bookings (id, customer_id, provider_id, service_id, service_name_en, service_name_bn, service_model,
    customer_name, customer_phone, provider_name, provider_phone, address_id, address_area, address_line1, address_line2,
    address_location, note, status, timing, scheduled_at, ends_at, accept_deadline, total_paisa, start_code,
    idempotency_key, created_at, updated_at)
VALUES (sqlc.arg(id), sqlc.arg(customer_id), sqlc.arg(provider_id), sqlc.arg(service_id), sqlc.arg(service_name_en),
    sqlc.arg(service_name_bn), sqlc.arg(service_model), sqlc.arg(customer_name), sqlc.arg(customer_phone),
    sqlc.arg(provider_name), sqlc.arg(provider_phone), sqlc.arg(address_id), sqlc.arg(address_area), sqlc.arg(address_line1),
    sqlc.arg(address_line2), ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography,
    sqlc.arg(note), sqlc.arg(status), sqlc.arg(timing), sqlc.narg(scheduled_at), sqlc.narg(ends_at), sqlc.arg(accept_deadline),
    sqlc.arg(total_paisa), sqlc.arg(start_code), sqlc.arg(idempotency_key), sqlc.arg(created_at), sqlc.arg(created_at))
RETURNING number;

-- name: BookingByID :one
SELECT id, number, customer_id, provider_id, service_id, service_name_en, service_name_bn, service_model, customer_name,
    customer_phone, provider_name, provider_phone, address_id, address_area, address_line1, address_line2,
    ST_Y(address_location::geometry)::float8 AS lat, ST_X(address_location::geometry)::float8 AS lng, note, status, timing,
    scheduled_at, ends_at, accept_deadline, total_paisa, start_code, start_code_attempts, start_code_locked_until,
    cash_received, idempotency_key, cancel_reason, cancelled_by, reject_reason, created_at, accepted_at, started_at,
    completed_at, cancelled_at
FROM booking.bookings WHERE id = $1;

-- name: LockBooking :one
SELECT provider_id FROM booking.bookings WHERE id = $1 FOR UPDATE;

-- name: LockProvider :exec
SELECT pg_advisory_xact_lock(hashtextextended(sqlc.arg(provider_id)::uuid::text, 0));

-- name: BookingIDByKey :one
SELECT id FROM booking.bookings WHERE customer_id = $1 AND idempotency_key = $2;

-- name: UpdateBooking :exec
UPDATE booking.bookings SET status = $2, total_paisa = $3, start_code_attempts = $4, start_code_locked_until = $5,
    cash_received = $6, cancel_reason = $7, cancelled_by = $8, reject_reason = $9, accepted_at = $10, started_at = $11,
    completed_at = $12, cancelled_at = $13, updated_at = $14, start_code = $15
WHERE id = $1;

-- name: InsertItem :exec
INSERT INTO booking.booking_items (id, booking_id, proposal_id, sub_service_id, price_version_id, name_en, name_bn, unit,
    quantity, unit_price_paisa, total_paisa, extra, position)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) ON CONFLICT (id) DO NOTHING;

-- name: ItemsByBooking :many
SELECT id, proposal_id, sub_service_id, price_version_id, name_en, name_bn, unit, quantity, unit_price_paisa, total_paisa,
    extra, position
FROM booking.booking_items WHERE booking_id = $1 ORDER BY position, id;

-- name: UpsertProposal :exec
INSERT INTO booking.extras_proposals (id, booking_id, status, added_paisa, proposed_at, decided_at) VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (id) DO UPDATE SET status = excluded.status, decided_at = excluded.decided_at;

-- name: ProposalsByBooking :many
SELECT id, status, added_paisa, proposed_at, decided_at FROM booking.extras_proposals WHERE booking_id = $1 ORDER BY proposed_at, id;

-- name: InsertTimeline :exec
INSERT INTO booking.timeline (id, booking_id, status, actor, reason, at) VALUES ($1, $2, $3, $4, $5, $6);

-- name: TimelineByBooking :many
SELECT id, status, actor, reason, at FROM booking.timeline WHERE booking_id = $1 ORDER BY at, id;

-- name: CountActive :one
SELECT count(*) FROM booking.bookings
WHERE provider_id = sqlc.arg(provider_id) AND id <> sqlc.arg(except_id) AND status IN ('accepted', 'on_the_way', 'arrived', 'in_progress');

-- name: DueRequests :many
SELECT id FROM booking.bookings WHERE status = 'requested' AND accept_deadline <= $1 ORDER BY accept_deadline LIMIT 500;

-- name: ListBookings :many
SELECT id, number, status, service_name_en, service_name_bn, customer_name, provider_name, timing, scheduled_at, total_paisa, created_at
FROM booking.bookings
WHERE (CASE WHEN sqlc.arg(as_provider)::bool THEN provider_id ELSE customer_id END) = sqlc.arg(party_id)
  AND (status = ANY(sqlc.arg(statuses)::text[]))
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (created_at, id) < (sqlc.narg(before_at), sqlc.arg(before_id)::uuid))
ORDER BY created_at DESC, id DESC LIMIT sqlc.arg(max_rows);

-- name: EarningsByDay :many
SELECT (completed_at AT TIME ZONE 'Asia/Dhaka')::date AS day, sum(total_paisa)::bigint AS total, count(*)::int AS jobs
FROM booking.bookings
WHERE provider_id = $1 AND status = 'completed' AND completed_at >= sqlc.arg(from_at) AND completed_at < sqlc.arg(until_at)
GROUP BY day ORDER BY day;

-- name: EarningsJobs :many
SELECT id, number, completed_at::timestamptz AS completed_at, service_name_en, service_name_bn, total_paisa
FROM booking.bookings
WHERE provider_id = sqlc.arg(provider_id) AND status = 'completed' AND completed_at >= sqlc.arg(from_at) AND completed_at < sqlc.arg(until_at)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (completed_at, id) < (sqlc.narg(before_at), sqlc.arg(before_id)::uuid))
ORDER BY completed_at DESC, id DESC LIMIT sqlc.arg(max_rows);

-- name: ProviderStats :one
SELECT count(*) FILTER (WHERE status = 'completed')::int AS completed,
    count(*) FILTER (WHERE status = 'cancelled' AND cancelled_by = 'provider' AND accepted_at IS NOT NULL AND cancelled_at > sqlc.arg(since))::int AS cancellations
FROM booking.bookings WHERE provider_id = sqlc.arg(provider_id);

-- name: AdminListBookings :many
SELECT id, number, status, service_name_en, service_name_bn, customer_name, provider_name, timing, scheduled_at, total_paisa, created_at
FROM booking.bookings
WHERE (sqlc.narg(status)::text IS NULL OR status = sqlc.narg(status)::text)
  AND (sqlc.narg(service_id)::uuid IS NULL OR service_id = sqlc.narg(service_id)::uuid)
  AND (sqlc.narg(from_at)::timestamptz IS NULL OR created_at >= sqlc.narg(from_at)::timestamptz)
  AND (sqlc.narg(until_at)::timestamptz IS NULL OR created_at < sqlc.narg(until_at)::timestamptz)
  AND (sqlc.arg(area)::text = '' OR lower(address_area) = lower(sqlc.arg(area)::text))
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (created_at, id) < (sqlc.narg(before_at)::timestamptz, sqlc.arg(before_id)::uuid))
ORDER BY created_at DESC, id DESC LIMIT sqlc.arg(max_rows);
