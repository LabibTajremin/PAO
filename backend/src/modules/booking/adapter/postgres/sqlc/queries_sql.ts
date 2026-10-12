import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const insertBookingQuery = `-- name: InsertBooking :one
INSERT INTO booking.bookings (id, customer_id, provider_id, service_id, service_name_en, service_name_bn, service_model,
    customer_name, customer_phone, provider_name, provider_phone, address_id, address_area, address_line1, address_line2,
    address_location, note, status, timing, scheduled_at, ends_at, accept_deadline, total_paisa, start_code,
    idempotency_key, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5,
    $6, $7, $8, $9,
    $10, $11, $12, $13, $14,
    $15, ST_SetSRID(ST_MakePoint($16::float8, $17::float8), 4326)::geography,
    $18, $19, $20, $21, $22, $23,
    $24, $25, $26, $27, $27)
RETURNING number`;

export interface InsertBookingArgs {
    id: string;
    customerId: string;
    providerId: string;
    serviceId: string;
    serviceNameEn: string;
    serviceNameBn: string;
    serviceModel: string;
    customerName: string;
    customerPhone: string;
    providerName: string;
    providerPhone: string;
    addressId: string;
    addressArea: string;
    addressLine1: string;
    addressLine2: string;
    lng: number;
    lat: number;
    note: string;
    status: string;
    timing: string;
    scheduledAt: Date | null;
    endsAt: Date | null;
    acceptDeadline: Date;
    totalPaisa: string;
    startCode: string;
    idempotencyKey: string;
    createdAt: Date;
}

export interface InsertBookingRow {
    number: string;
}

export async function insertBooking(client: Client, args: InsertBookingArgs): Promise<InsertBookingRow | null> {
    const result = await client.query({
        text: insertBookingQuery,
        values: [args.id, args.customerId, args.providerId, args.serviceId, args.serviceNameEn, args.serviceNameBn, args.serviceModel, args.customerName, args.customerPhone, args.providerName, args.providerPhone, args.addressId, args.addressArea, args.addressLine1, args.addressLine2, args.lng, args.lat, args.note, args.status, args.timing, args.scheduledAt, args.endsAt, args.acceptDeadline, args.totalPaisa, args.startCode, args.idempotencyKey, args.createdAt],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        number: row[0]
    };
}

export const bookingByIDQuery = `-- name: BookingByID :one
SELECT id, number, customer_id, provider_id, service_id, service_name_en, service_name_bn, service_model, customer_name,
    customer_phone, provider_name, provider_phone, address_id, address_area, address_line1, address_line2,
    ST_Y(address_location::geometry)::float8 AS lat, ST_X(address_location::geometry)::float8 AS lng, note, status, timing,
    scheduled_at, ends_at, accept_deadline, total_paisa, start_code, start_code_attempts, start_code_locked_until,
    cash_received, idempotency_key, cancel_reason, cancelled_by, reject_reason, created_at, accepted_at, started_at,
    completed_at, cancelled_at
FROM booking.bookings WHERE id = $1`;

export interface BookingByIDArgs {
    id: string;
}

export interface BookingByIDRow {
    id: string;
    number: string;
    customerId: string;
    providerId: string;
    serviceId: string;
    serviceNameEn: string;
    serviceNameBn: string;
    serviceModel: string;
    customerName: string;
    customerPhone: string;
    providerName: string;
    providerPhone: string;
    addressId: string;
    addressArea: string;
    addressLine1: string;
    addressLine2: string;
    lat: number;
    lng: number;
    note: string;
    status: string;
    timing: string;
    scheduledAt: Date | null;
    endsAt: Date | null;
    acceptDeadline: Date;
    totalPaisa: string;
    startCode: string;
    startCodeAttempts: number;
    startCodeLockedUntil: Date | null;
    cashReceived: boolean;
    idempotencyKey: string;
    cancelReason: string;
    cancelledBy: string | null;
    rejectReason: string;
    createdAt: Date;
    acceptedAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    cancelledAt: Date | null;
}

export async function bookingByID(client: Client, args: BookingByIDArgs): Promise<BookingByIDRow | null> {
    const result = await client.query({
        text: bookingByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        number: row[1],
        customerId: row[2],
        providerId: row[3],
        serviceId: row[4],
        serviceNameEn: row[5],
        serviceNameBn: row[6],
        serviceModel: row[7],
        customerName: row[8],
        customerPhone: row[9],
        providerName: row[10],
        providerPhone: row[11],
        addressId: row[12],
        addressArea: row[13],
        addressLine1: row[14],
        addressLine2: row[15],
        lat: row[16],
        lng: row[17],
        note: row[18],
        status: row[19],
        timing: row[20],
        scheduledAt: row[21],
        endsAt: row[22],
        acceptDeadline: row[23],
        totalPaisa: row[24],
        startCode: row[25],
        startCodeAttempts: row[26],
        startCodeLockedUntil: row[27],
        cashReceived: row[28],
        idempotencyKey: row[29],
        cancelReason: row[30],
        cancelledBy: row[31],
        rejectReason: row[32],
        createdAt: row[33],
        acceptedAt: row[34],
        startedAt: row[35],
        completedAt: row[36],
        cancelledAt: row[37]
    };
}

export const lockBookingQuery = `-- name: LockBooking :one
SELECT provider_id FROM booking.bookings WHERE id = $1 FOR UPDATE`;

export interface LockBookingArgs {
    id: string;
}

export interface LockBookingRow {
    providerId: string;
}

export async function lockBooking(client: Client, args: LockBookingArgs): Promise<LockBookingRow | null> {
    const result = await client.query({
        text: lockBookingQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        providerId: row[0]
    };
}

export const lockProviderQuery = `-- name: LockProvider :exec
SELECT pg_advisory_xact_lock(hashtextextended($1::uuid::text, 0))`;

export interface LockProviderArgs {
    providerId: string;
}

export interface LockProviderRow {
    pgAdvisoryXactLock: string;
}

export async function lockProvider(client: Client, args: LockProviderArgs): Promise<void> {
    await client.query({
        text: lockProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const bookingIDByKeyQuery = `-- name: BookingIDByKey :one
SELECT id FROM booking.bookings WHERE customer_id = $1 AND idempotency_key = $2`;

export interface BookingIDByKeyArgs {
    customerId: string;
    idempotencyKey: string;
}

export interface BookingIDByKeyRow {
    id: string;
}

export async function bookingIDByKey(client: Client, args: BookingIDByKeyArgs): Promise<BookingIDByKeyRow | null> {
    const result = await client.query({
        text: bookingIDByKeyQuery,
        values: [args.customerId, args.idempotencyKey],
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

export const updateBookingQuery = `-- name: UpdateBooking :exec
UPDATE booking.bookings SET status = $2, total_paisa = $3, start_code_attempts = $4, start_code_locked_until = $5,
    cash_received = $6, cancel_reason = $7, cancelled_by = $8, reject_reason = $9, accepted_at = $10, started_at = $11,
    completed_at = $12, cancelled_at = $13, updated_at = $14, start_code = $15
WHERE id = $1`;

export interface UpdateBookingArgs {
    id: string;
    status: string;
    totalPaisa: string;
    startCodeAttempts: number;
    startCodeLockedUntil: Date | null;
    cashReceived: boolean;
    cancelReason: string;
    cancelledBy: string | null;
    rejectReason: string;
    acceptedAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    cancelledAt: Date | null;
    updatedAt: Date;
    startCode: string;
}

export async function updateBooking(client: Client, args: UpdateBookingArgs): Promise<void> {
    await client.query({
        text: updateBookingQuery,
        values: [args.id, args.status, args.totalPaisa, args.startCodeAttempts, args.startCodeLockedUntil, args.cashReceived, args.cancelReason, args.cancelledBy, args.rejectReason, args.acceptedAt, args.startedAt, args.completedAt, args.cancelledAt, args.updatedAt, args.startCode],
        rowMode: "array"
    });
}

export const insertItemQuery = `-- name: InsertItem :exec
INSERT INTO booking.booking_items (id, booking_id, proposal_id, sub_service_id, price_version_id, name_en, name_bn, unit,
    quantity, unit_price_paisa, total_paisa, extra, position)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) ON CONFLICT (id) DO NOTHING`;

export interface InsertItemArgs {
    id: string;
    bookingId: string;
    proposalId: string | null;
    subServiceId: string;
    priceVersionId: string;
    nameEn: string;
    nameBn: string;
    unit: string;
    quantity: number;
    unitPricePaisa: string;
    totalPaisa: string;
    extra: boolean;
    position: number;
}

export async function insertItem(client: Client, args: InsertItemArgs): Promise<void> {
    await client.query({
        text: insertItemQuery,
        values: [args.id, args.bookingId, args.proposalId, args.subServiceId, args.priceVersionId, args.nameEn, args.nameBn, args.unit, args.quantity, args.unitPricePaisa, args.totalPaisa, args.extra, args.position],
        rowMode: "array"
    });
}

export const itemsByBookingQuery = `-- name: ItemsByBooking :many
SELECT id, proposal_id, sub_service_id, price_version_id, name_en, name_bn, unit, quantity, unit_price_paisa, total_paisa,
    extra, position
FROM booking.booking_items WHERE booking_id = $1 ORDER BY position, id`;

export interface ItemsByBookingArgs {
    bookingId: string;
}

export interface ItemsByBookingRow {
    id: string;
    proposalId: string | null;
    subServiceId: string;
    priceVersionId: string;
    nameEn: string;
    nameBn: string;
    unit: string;
    quantity: number;
    unitPricePaisa: string;
    totalPaisa: string;
    extra: boolean;
    position: number;
}

export async function itemsByBooking(client: Client, args: ItemsByBookingArgs): Promise<ItemsByBookingRow[]> {
    const result = await client.query({
        text: itemsByBookingQuery,
        values: [args.bookingId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            proposalId: row[1],
            subServiceId: row[2],
            priceVersionId: row[3],
            nameEn: row[4],
            nameBn: row[5],
            unit: row[6],
            quantity: row[7],
            unitPricePaisa: row[8],
            totalPaisa: row[9],
            extra: row[10],
            position: row[11]
        };
    });
}

export const upsertProposalQuery = `-- name: UpsertProposal :exec
INSERT INTO booking.extras_proposals (id, booking_id, status, added_paisa, proposed_at, decided_at) VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (id) DO UPDATE SET status = excluded.status, decided_at = excluded.decided_at`;

export interface UpsertProposalArgs {
    id: string;
    bookingId: string;
    status: string;
    addedPaisa: string;
    proposedAt: Date;
    decidedAt: Date | null;
}

export async function upsertProposal(client: Client, args: UpsertProposalArgs): Promise<void> {
    await client.query({
        text: upsertProposalQuery,
        values: [args.id, args.bookingId, args.status, args.addedPaisa, args.proposedAt, args.decidedAt],
        rowMode: "array"
    });
}

export const proposalsByBookingQuery = `-- name: ProposalsByBooking :many
SELECT id, status, added_paisa, proposed_at, decided_at FROM booking.extras_proposals WHERE booking_id = $1 ORDER BY proposed_at, id`;

export interface ProposalsByBookingArgs {
    bookingId: string;
}

export interface ProposalsByBookingRow {
    id: string;
    status: string;
    addedPaisa: string;
    proposedAt: Date;
    decidedAt: Date | null;
}

export async function proposalsByBooking(client: Client, args: ProposalsByBookingArgs): Promise<ProposalsByBookingRow[]> {
    const result = await client.query({
        text: proposalsByBookingQuery,
        values: [args.bookingId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            status: row[1],
            addedPaisa: row[2],
            proposedAt: row[3],
            decidedAt: row[4]
        };
    });
}

export const insertTimelineQuery = `-- name: InsertTimeline :exec
INSERT INTO booking.timeline (id, booking_id, status, actor, reason, at) VALUES ($1, $2, $3, $4, $5, $6)`;

export interface InsertTimelineArgs {
    id: string;
    bookingId: string;
    status: string;
    actor: string;
    reason: string;
    at: Date;
}

export async function insertTimeline(client: Client, args: InsertTimelineArgs): Promise<void> {
    await client.query({
        text: insertTimelineQuery,
        values: [args.id, args.bookingId, args.status, args.actor, args.reason, args.at],
        rowMode: "array"
    });
}

export const timelineByBookingQuery = `-- name: TimelineByBooking :many
SELECT id, status, actor, reason, at FROM booking.timeline WHERE booking_id = $1 ORDER BY at, id`;

export interface TimelineByBookingArgs {
    bookingId: string;
}

export interface TimelineByBookingRow {
    id: string;
    status: string;
    actor: string;
    reason: string;
    at: Date;
}

export async function timelineByBooking(client: Client, args: TimelineByBookingArgs): Promise<TimelineByBookingRow[]> {
    const result = await client.query({
        text: timelineByBookingQuery,
        values: [args.bookingId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            status: row[1],
            actor: row[2],
            reason: row[3],
            at: row[4]
        };
    });
}

export const countActiveQuery = `-- name: CountActive :one
SELECT count(*) FROM booking.bookings
WHERE provider_id = $1 AND id <> $2 AND status IN ('accepted', 'on_the_way', 'arrived', 'in_progress')`;

export interface CountActiveArgs {
    providerId: string;
    exceptId: string;
}

export interface CountActiveRow {
    count: string;
}

export async function countActive(client: Client, args: CountActiveArgs): Promise<CountActiveRow | null> {
    const result = await client.query({
        text: countActiveQuery,
        values: [args.providerId, args.exceptId],
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

export const dueRequestsQuery = `-- name: DueRequests :many
SELECT id FROM booking.bookings WHERE status = 'requested' AND accept_deadline <= $1 ORDER BY accept_deadline LIMIT 500`;

export interface DueRequestsArgs {
    acceptDeadline: Date;
}

export interface DueRequestsRow {
    id: string;
}

export async function dueRequests(client: Client, args: DueRequestsArgs): Promise<DueRequestsRow[]> {
    const result = await client.query({
        text: dueRequestsQuery,
        values: [args.acceptDeadline],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0]
        };
    });
}

export const listBookingsQuery = `-- name: ListBookings :many
SELECT id, number, status, service_name_en, service_name_bn, customer_name, provider_name, timing, scheduled_at, total_paisa, created_at
FROM booking.bookings
WHERE (CASE WHEN $1::bool THEN provider_id ELSE customer_id END) = $2
  AND (status = ANY($3::text[]))
  AND ($4::timestamptz IS NULL OR (created_at, id) < ($4, $5::uuid))
ORDER BY created_at DESC, id DESC LIMIT $6`;

export interface ListBookingsArgs {
    asProvider: boolean;
    partyId: string;
    statuses: string[];
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface ListBookingsRow {
    id: string;
    number: string;
    status: string;
    serviceNameEn: string;
    serviceNameBn: string;
    customerName: string;
    providerName: string;
    timing: string;
    scheduledAt: Date | null;
    totalPaisa: string;
    createdAt: Date;
}

export async function listBookings(client: Client, args: ListBookingsArgs): Promise<ListBookingsRow[]> {
    const result = await client.query({
        text: listBookingsQuery,
        values: [args.asProvider, args.partyId, args.statuses, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            number: row[1],
            status: row[2],
            serviceNameEn: row[3],
            serviceNameBn: row[4],
            customerName: row[5],
            providerName: row[6],
            timing: row[7],
            scheduledAt: row[8],
            totalPaisa: row[9],
            createdAt: row[10]
        };
    });
}

export const earningsByDayQuery = `-- name: EarningsByDay :many
SELECT (completed_at AT TIME ZONE 'Asia/Dhaka')::date AS day, sum(total_paisa)::bigint AS total, count(*)::int AS jobs
FROM booking.bookings
WHERE provider_id = $1 AND status = 'completed' AND completed_at >= $2 AND completed_at < $3
GROUP BY day ORDER BY day`;

export interface EarningsByDayArgs {
    providerId: string;
    fromAt: Date | null;
    untilAt: Date | null;
}

export interface EarningsByDayRow {
    day: Date;
    total: string;
    jobs: number;
}

export async function earningsByDay(client: Client, args: EarningsByDayArgs): Promise<EarningsByDayRow[]> {
    const result = await client.query({
        text: earningsByDayQuery,
        values: [args.providerId, args.fromAt, args.untilAt],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            day: row[0],
            total: row[1],
            jobs: row[2]
        };
    });
}

export const earningsJobsQuery = `-- name: EarningsJobs :many
SELECT id, number, completed_at::timestamptz AS completed_at, service_name_en, service_name_bn, total_paisa
FROM booking.bookings
WHERE provider_id = $1 AND status = 'completed' AND completed_at >= $2 AND completed_at < $3
  AND ($4::timestamptz IS NULL OR (completed_at, id) < ($4, $5::uuid))
ORDER BY completed_at DESC, id DESC LIMIT $6`;

export interface EarningsJobsArgs {
    providerId: string;
    fromAt: Date | null;
    untilAt: Date | null;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface EarningsJobsRow {
    id: string;
    number: string;
    completedAt: Date;
    serviceNameEn: string;
    serviceNameBn: string;
    totalPaisa: string;
}

export async function earningsJobs(client: Client, args: EarningsJobsArgs): Promise<EarningsJobsRow[]> {
    const result = await client.query({
        text: earningsJobsQuery,
        values: [args.providerId, args.fromAt, args.untilAt, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            number: row[1],
            completedAt: row[2],
            serviceNameEn: row[3],
            serviceNameBn: row[4],
            totalPaisa: row[5]
        };
    });
}

export const providerStatsQuery = `-- name: ProviderStats :one
SELECT count(*) FILTER (WHERE status = 'completed')::int AS completed,
    count(*) FILTER (WHERE status = 'cancelled' AND cancelled_by = 'provider' AND accepted_at IS NOT NULL AND cancelled_at > $1)::int AS cancellations
FROM booking.bookings WHERE provider_id = $2`;

export interface ProviderStatsArgs {
    since: Date | null;
    providerId: string;
}

export interface ProviderStatsRow {
    completed: number;
    cancellations: number;
}

export async function providerStats(client: Client, args: ProviderStatsArgs): Promise<ProviderStatsRow | null> {
    const result = await client.query({
        text: providerStatsQuery,
        values: [args.since, args.providerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        completed: row[0],
        cancellations: row[1]
    };
}

export const adminListBookingsQuery = `-- name: AdminListBookings :many
SELECT id, number, status, service_name_en, service_name_bn, customer_name, provider_name, timing, scheduled_at, total_paisa, created_at
FROM booking.bookings
WHERE ($1::text IS NULL OR status = $1::text)
  AND ($2::uuid IS NULL OR service_id = $2::uuid)
  AND ($3::timestamptz IS NULL OR created_at >= $3::timestamptz)
  AND ($4::timestamptz IS NULL OR created_at < $4::timestamptz)
  AND ($5::text = '' OR lower(address_area) = lower($5::text))
  AND ($6::timestamptz IS NULL OR (created_at, id) < ($6::timestamptz, $7::uuid))
ORDER BY created_at DESC, id DESC LIMIT $8`;

export interface AdminListBookingsArgs {
    status: string | null;
    serviceId: string | null;
    fromAt: Date | null;
    untilAt: Date | null;
    area: string;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface AdminListBookingsRow {
    id: string;
    number: string;
    status: string;
    serviceNameEn: string;
    serviceNameBn: string;
    customerName: string;
    providerName: string;
    timing: string;
    scheduledAt: Date | null;
    totalPaisa: string;
    createdAt: Date;
}

export async function adminListBookings(client: Client, args: AdminListBookingsArgs): Promise<AdminListBookingsRow[]> {
    const result = await client.query({
        text: adminListBookingsQuery,
        values: [args.status, args.serviceId, args.fromAt, args.untilAt, args.area, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            number: row[1],
            status: row[2],
            serviceNameEn: row[3],
            serviceNameBn: row[4],
            customerName: row[5],
            providerName: row[6],
            timing: row[7],
            scheduledAt: row[8],
            totalPaisa: row[9],
            createdAt: row[10]
        };
    });
}

