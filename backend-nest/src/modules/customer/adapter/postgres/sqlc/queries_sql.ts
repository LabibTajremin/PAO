import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const upsertCustomerQuery = `-- name: UpsertCustomer :exec
INSERT INTO customer.customers (id, name, photo_media_id, language, created_at, updated_at, phone, account_status)
VALUES ($1, $2, $3, $4, $5, $5, $6, $7)
ON CONFLICT (id) DO UPDATE SET name = excluded.name, photo_media_id = excluded.photo_media_id,
    language = excluded.language, updated_at = excluded.updated_at, phone = excluded.phone,
    account_status = excluded.account_status`;

export interface UpsertCustomerArgs {
    id: string;
    name: string;
    photoMediaId: string | null;
    language: string;
    createdAt: Date;
    phone: string;
    accountStatus: string;
}

export async function upsertCustomer(client: Client, args: UpsertCustomerArgs): Promise<void> {
    await client.query({
        text: upsertCustomerQuery,
        values: [args.id, args.name, args.photoMediaId, args.language, args.createdAt, args.phone, args.accountStatus],
        rowMode: "array"
    });
}

export const customerByIDQuery = `-- name: CustomerByID :one
SELECT id, name, photo_media_id, language, updated_at FROM customer.customers WHERE id = $1`;

export interface CustomerByIDArgs {
    id: string;
}

export interface CustomerByIDRow {
    id: string;
    name: string;
    photoMediaId: string | null;
    language: string;
    updatedAt: Date;
}

export async function customerByID(client: Client, args: CustomerByIDArgs): Promise<CustomerByIDRow | null> {
    const result = await client.query({
        text: customerByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        name: row[1],
        photoMediaId: row[2],
        language: row[3],
        updatedAt: row[4]
    };
}

export const lockCustomerQuery = `-- name: LockCustomer :one
SELECT id FROM customer.customers WHERE id = $1 FOR UPDATE`;

export interface LockCustomerArgs {
    id: string;
}

export interface LockCustomerRow {
    id: string;
}

export async function lockCustomer(client: Client, args: LockCustomerArgs): Promise<LockCustomerRow | null> {
    const result = await client.query({
        text: lockCustomerQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0]
    };
}

export const deleteCustomerQuery = `-- name: DeleteCustomer :exec
DELETE FROM customer.customers WHERE id = $1`;

export interface DeleteCustomerArgs {
    id: string;
}

export async function deleteCustomer(client: Client, args: DeleteCustomerArgs): Promise<void> {
    await client.query({
        text: deleteCustomerQuery,
        values: [args.id],
        rowMode: "array"
    });
}

export const countAddressesQuery = `-- name: CountAddresses :one
SELECT count(*) FROM customer.addresses WHERE customer_id = $1`;

export interface CountAddressesArgs {
    customerId: string;
}

export interface CountAddressesRow {
    count: string;
}

export async function countAddresses(client: Client, args: CountAddressesArgs): Promise<CountAddressesRow | null> {
    const result = await client.query({
        text: countAddressesQuery,
        values: [args.customerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        count: row[0]
    };
}

export const insertAddressQuery = `-- name: InsertAddress :exec
INSERT INTO customer.addresses (id, customer_id, label, line1, line2, area, location, is_default, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6,
    ST_SetSRID(ST_MakePoint($7::float8, $8::float8), 4326)::geography,
    $9, $10, $10)`;

export interface InsertAddressArgs {
    id: string;
    customerId: string;
    label: string;
    line1: string;
    line2: string;
    area: string;
    lng: number;
    lat: number;
    isDefault: boolean;
    createdAt: Date;
}

export async function insertAddress(client: Client, args: InsertAddressArgs): Promise<void> {
    await client.query({
        text: insertAddressQuery,
        values: [args.id, args.customerId, args.label, args.line1, args.line2, args.area, args.lng, args.lat, args.isDefault, args.createdAt],
        rowMode: "array"
    });
}

export const updateAddressQuery = `-- name: UpdateAddress :execrows
UPDATE customer.addresses SET label = $1, line1 = $2, line2 = $3, area = $4,
    location = ST_SetSRID(ST_MakePoint($5::float8, $6::float8), 4326)::geography,
    updated_at = $7
WHERE id = $8 AND customer_id = $9`;

export interface UpdateAddressArgs {
    label: string;
    line1: string;
    line2: string;
    area: string;
    lng: number;
    lat: number;
    updatedAt: Date;
    id: string;
    customerId: string;
}

export const clearDefaultQuery = `-- name: ClearDefault :exec
UPDATE customer.addresses SET is_default = false WHERE customer_id = $1 AND is_default`;

export interface ClearDefaultArgs {
    customerId: string;
}

export async function clearDefault(client: Client, args: ClearDefaultArgs): Promise<void> {
    await client.query({
        text: clearDefaultQuery,
        values: [args.customerId],
        rowMode: "array"
    });
}

export const markDefaultQuery = `-- name: MarkDefault :execrows
UPDATE customer.addresses SET is_default = true WHERE id = $1 AND customer_id = $2`;

export interface MarkDefaultArgs {
    id: string;
    customerId: string;
}

export const deleteAddressQuery = `-- name: DeleteAddress :one
DELETE FROM customer.addresses WHERE id = $1 AND customer_id = $2 RETURNING is_default`;

export interface DeleteAddressArgs {
    id: string;
    customerId: string;
}

export interface DeleteAddressRow {
    isDefault: boolean;
}

export async function deleteAddress(client: Client, args: DeleteAddressArgs): Promise<DeleteAddressRow | null> {
    const result = await client.query({
        text: deleteAddressQuery,
        values: [args.id, args.customerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        isDefault: row[0]
    };
}

export const promoteNewestQuery = `-- name: PromoteNewest :exec
UPDATE customer.addresses SET is_default = true
WHERE id = (SELECT a.id FROM customer.addresses a WHERE a.customer_id = $1 ORDER BY a.created_at DESC, a.id DESC LIMIT 1)`;

export interface PromoteNewestArgs {
    customerId: string;
}

export async function promoteNewest(client: Client, args: PromoteNewestArgs): Promise<void> {
    await client.query({
        text: promoteNewestQuery,
        values: [args.customerId],
        rowMode: "array"
    });
}

export const listAddressesQuery = `-- name: ListAddresses :many
SELECT id, customer_id, label, line1, line2, area, ST_Y(location::geometry)::float8 AS lat,
    ST_X(location::geometry)::float8 AS lng, is_default, created_at
FROM customer.addresses WHERE customer_id = $1 ORDER BY is_default DESC, created_at DESC, id DESC`;

export interface ListAddressesArgs {
    customerId: string;
}

export interface ListAddressesRow {
    id: string;
    customerId: string;
    label: string;
    line1: string;
    line2: string;
    area: string;
    lat: number;
    lng: number;
    isDefault: boolean;
    createdAt: Date;
}

export async function listAddresses(client: Client, args: ListAddressesArgs): Promise<ListAddressesRow[]> {
    const result = await client.query({
        text: listAddressesQuery,
        values: [args.customerId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            customerId: row[1],
            label: row[2],
            line1: row[3],
            line2: row[4],
            area: row[5],
            lat: row[6],
            lng: row[7],
            isDefault: row[8],
            createdAt: row[9]
        };
    });
}

export const addressByIDQuery = `-- name: AddressByID :one
SELECT id, customer_id, label, line1, line2, area, ST_Y(location::geometry)::float8 AS lat,
    ST_X(location::geometry)::float8 AS lng, is_default, created_at
FROM customer.addresses WHERE id = $1 AND customer_id = $2`;

export interface AddressByIDArgs {
    id: string;
    customerId: string;
}

export interface AddressByIDRow {
    id: string;
    customerId: string;
    label: string;
    line1: string;
    line2: string;
    area: string;
    lat: number;
    lng: number;
    isDefault: boolean;
    createdAt: Date;
}

export async function addressByID(client: Client, args: AddressByIDArgs): Promise<AddressByIDRow | null> {
    const result = await client.query({
        text: addressByIDQuery,
        values: [args.id, args.customerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        customerId: row[1],
        label: row[2],
        line1: row[3],
        line2: row[4],
        area: row[5],
        lat: row[6],
        lng: row[7],
        isDefault: row[8],
        createdAt: row[9]
    };
}

export const setCustomerStatusQuery = `-- name: SetCustomerStatus :exec
UPDATE customer.customers SET account_status = $2 WHERE id = $1`;

export interface SetCustomerStatusArgs {
    id: string;
    accountStatus: string;
}

export async function setCustomerStatus(client: Client, args: SetCustomerStatusArgs): Promise<void> {
    await client.query({
        text: setCustomerStatusQuery,
        values: [args.id, args.accountStatus],
        rowMode: "array"
    });
}

export const countCustomerBookingQuery = `-- name: CountCustomerBooking :exec
UPDATE customer.customers SET bookings = bookings + 1 WHERE id = $1`;

export interface CountCustomerBookingArgs {
    id: string;
}

export async function countCustomerBooking(client: Client, args: CountCustomerBookingArgs): Promise<void> {
    await client.query({
        text: countCustomerBookingQuery,
        values: [args.id],
        rowMode: "array"
    });
}

export const searchCustomersQuery = `-- name: SearchCustomers :many
SELECT id, name, phone, account_status, bookings, created_at FROM customer.customers
WHERE ($1::uuid IS NULL OR id = $1::uuid)
  AND ($2::text = '' OR lower(name) LIKE $2::text OR phone LIKE $2::text)
  AND ($3::text IS NULL OR account_status = $3::text)
  AND ($4::timestamptz IS NULL OR (created_at, id) < ($4::timestamptz, $5::uuid))
ORDER BY created_at DESC, id DESC
LIMIT $6`;

export interface SearchCustomersArgs {
    id: string | null;
    pattern: string;
    status: string | null;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface SearchCustomersRow {
    id: string;
    name: string;
    phone: string;
    accountStatus: string;
    bookings: number;
    createdAt: Date;
}

export async function searchCustomers(client: Client, args: SearchCustomersArgs): Promise<SearchCustomersRow[]> {
    const result = await client.query({
        text: searchCustomersQuery,
        values: [args.id, args.pattern, args.status, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            name: row[1],
            phone: row[2],
            accountStatus: row[3],
            bookings: row[4],
            createdAt: row[5]
        };
    });
}

