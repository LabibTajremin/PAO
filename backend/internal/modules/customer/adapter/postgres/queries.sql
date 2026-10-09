-- name: UpsertCustomer :exec
INSERT INTO customer.customers (id, name, photo_media_id, language, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $5)
ON CONFLICT (id) DO UPDATE SET name = excluded.name, photo_media_id = excluded.photo_media_id,
    language = excluded.language, updated_at = excluded.updated_at;

-- name: CustomerByID :one
SELECT id, name, photo_media_id, language, updated_at FROM customer.customers WHERE id = $1;

-- name: LockCustomer :one
SELECT id FROM customer.customers WHERE id = $1 FOR UPDATE;

-- name: DeleteCustomer :exec
DELETE FROM customer.customers WHERE id = $1;

-- name: CountAddresses :one
SELECT count(*) FROM customer.addresses WHERE customer_id = $1;

-- name: InsertAddress :exec
INSERT INTO customer.addresses (id, customer_id, label, line1, line2, area, location, is_default, created_at, updated_at)
VALUES (sqlc.arg(id), sqlc.arg(customer_id), sqlc.arg(label), sqlc.arg(line1), sqlc.arg(line2), sqlc.arg(area),
    ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography,
    sqlc.arg(is_default), sqlc.arg(created_at), sqlc.arg(created_at));

-- name: UpdateAddress :execrows
UPDATE customer.addresses SET label = sqlc.arg(label), line1 = sqlc.arg(line1), line2 = sqlc.arg(line2), area = sqlc.arg(area),
    location = ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography,
    updated_at = sqlc.arg(updated_at)
WHERE id = sqlc.arg(id) AND customer_id = sqlc.arg(customer_id);

-- name: ClearDefault :exec
UPDATE customer.addresses SET is_default = false WHERE customer_id = $1 AND is_default;

-- name: MarkDefault :execrows
UPDATE customer.addresses SET is_default = true WHERE id = $1 AND customer_id = $2;

-- name: DeleteAddress :one
DELETE FROM customer.addresses WHERE id = $1 AND customer_id = $2 RETURNING is_default;

-- name: PromoteNewest :exec
UPDATE customer.addresses SET is_default = true
WHERE id = (SELECT a.id FROM customer.addresses a WHERE a.customer_id = $1 ORDER BY a.created_at DESC, a.id DESC LIMIT 1);

-- name: ListAddresses :many
SELECT id, customer_id, label, line1, line2, area, ST_Y(location::geometry)::float8 AS lat,
    ST_X(location::geometry)::float8 AS lng, is_default, created_at
FROM customer.addresses WHERE customer_id = $1 ORDER BY is_default DESC, created_at DESC, id DESC;

-- name: AddressByID :one
SELECT id, customer_id, label, line1, line2, area, ST_Y(location::geometry)::float8 AS lat,
    ST_X(location::geometry)::float8 AS lng, is_default, created_at
FROM customer.addresses WHERE id = $1 AND customer_id = $2;
