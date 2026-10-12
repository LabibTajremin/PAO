import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const listSettingsQuery = `-- name: ListSettings :many
SELECT key, value, type, description, updated_at, updated_by FROM admin.settings ORDER BY key`;

export interface ListSettingsRow {
    key: string;
    value: string;
    type: string;
    description: string;
    updatedAt: Date;
    updatedBy: string | null;
}

export async function listSettings(client: Client): Promise<ListSettingsRow[]> {
    const result = await client.query({
        text: listSettingsQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            key: row[0],
            value: row[1],
            type: row[2],
            description: row[3],
            updatedAt: row[4],
            updatedBy: row[5]
        };
    });
}

export const settingByKeyQuery = `-- name: SettingByKey :one
SELECT key, value, type, description, updated_at, updated_by FROM admin.settings WHERE key = $1`;

export interface SettingByKeyArgs {
    key: string;
}

export interface SettingByKeyRow {
    key: string;
    value: string;
    type: string;
    description: string;
    updatedAt: Date;
    updatedBy: string | null;
}

export async function settingByKey(client: Client, args: SettingByKeyArgs): Promise<SettingByKeyRow | null> {
    const result = await client.query({
        text: settingByKeyQuery,
        values: [args.key],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        key: row[0],
        value: row[1],
        type: row[2],
        description: row[3],
        updatedAt: row[4],
        updatedBy: row[5]
    };
}

export const updateSettingQuery = `-- name: UpdateSetting :exec
UPDATE admin.settings SET value = $2, updated_at = $3, updated_by = $4 WHERE key = $1`;

export interface UpdateSettingArgs {
    key: string;
    value: string;
    updatedAt: Date;
    updatedBy: string | null;
}

export async function updateSetting(client: Client, args: UpdateSettingArgs): Promise<void> {
    await client.query({
        text: updateSettingQuery,
        values: [args.key, args.value, args.updatedAt, args.updatedBy],
        rowMode: "array"
    });
}

export const countVerifiedComplaintsQuery = `-- name: CountVerifiedComplaints :one
SELECT count(*) FROM admin.complaints WHERE against_id = $1 AND verified`;

export interface CountVerifiedComplaintsArgs {
    againstId: string;
}

export interface CountVerifiedComplaintsRow {
    count: string;
}

export async function countVerifiedComplaints(client: Client, args: CountVerifiedComplaintsArgs): Promise<CountVerifiedComplaintsRow | null> {
    const result = await client.query({
        text: countVerifiedComplaintsQuery,
        values: [args.againstId],
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

export const insertComplaintQuery = `-- name: InsertComplaint :one
INSERT INTO admin.complaints (id, booking_id, reporter_id, reporter_role, against_id, reason, description, photo_media_ids, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)
RETURNING ticket_number`;

export interface InsertComplaintArgs {
    id: string;
    bookingId: string;
    reporterId: string;
    reporterRole: string;
    againstId: string;
    reason: string;
    description: string;
    photoMediaIds: string[];
    createdAt: Date;
}

export interface InsertComplaintRow {
    ticketNumber: string;
}

export async function insertComplaint(client: Client, args: InsertComplaintArgs): Promise<InsertComplaintRow | null> {
    const result = await client.query({
        text: insertComplaintQuery,
        values: [args.id, args.bookingId, args.reporterId, args.reporterRole, args.againstId, args.reason, args.description, args.photoMediaIds, args.createdAt],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        ticketNumber: row[0]
    };
}

export const complaintByIDQuery = `-- name: ComplaintByID :one
SELECT id, ticket_number, booking_id, reporter_id, reporter_role, against_id, reason, description, photo_media_ids, status, assignee_id, resolution, verified, created_at, updated_at, resolved_at FROM admin.complaints WHERE id = $1`;

export interface ComplaintByIDArgs {
    id: string;
}

export interface ComplaintByIDRow {
    id: string;
    ticketNumber: string;
    bookingId: string;
    reporterId: string;
    reporterRole: string;
    againstId: string;
    reason: string;
    description: string;
    photoMediaIds: string[];
    status: string;
    assigneeId: string | null;
    resolution: string;
    verified: boolean;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt: Date | null;
}

export async function complaintByID(client: Client, args: ComplaintByIDArgs): Promise<ComplaintByIDRow | null> {
    const result = await client.query({
        text: complaintByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        ticketNumber: row[1],
        bookingId: row[2],
        reporterId: row[3],
        reporterRole: row[4],
        againstId: row[5],
        reason: row[6],
        description: row[7],
        photoMediaIds: row[8],
        status: row[9],
        assigneeId: row[10],
        resolution: row[11],
        verified: row[12],
        createdAt: row[13],
        updatedAt: row[14],
        resolvedAt: row[15]
    };
}

export const lockComplaintQuery = `-- name: LockComplaint :one
SELECT id, ticket_number, booking_id, reporter_id, reporter_role, against_id, reason, description, photo_media_ids, status, assignee_id, resolution, verified, created_at, updated_at, resolved_at FROM admin.complaints WHERE id = $1 FOR UPDATE`;

export interface LockComplaintArgs {
    id: string;
}

export interface LockComplaintRow {
    id: string;
    ticketNumber: string;
    bookingId: string;
    reporterId: string;
    reporterRole: string;
    againstId: string;
    reason: string;
    description: string;
    photoMediaIds: string[];
    status: string;
    assigneeId: string | null;
    resolution: string;
    verified: boolean;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt: Date | null;
}

export async function lockComplaint(client: Client, args: LockComplaintArgs): Promise<LockComplaintRow | null> {
    const result = await client.query({
        text: lockComplaintQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        ticketNumber: row[1],
        bookingId: row[2],
        reporterId: row[3],
        reporterRole: row[4],
        againstId: row[5],
        reason: row[6],
        description: row[7],
        photoMediaIds: row[8],
        status: row[9],
        assigneeId: row[10],
        resolution: row[11],
        verified: row[12],
        createdAt: row[13],
        updatedAt: row[14],
        resolvedAt: row[15]
    };
}

export const updateComplaintQuery = `-- name: UpdateComplaint :exec
UPDATE admin.complaints
SET status = $2, assignee_id = $3, resolution = $4, verified = $5, updated_at = $6, resolved_at = $7
WHERE id = $1`;

export interface UpdateComplaintArgs {
    id: string;
    status: string;
    assigneeId: string | null;
    resolution: string;
    verified: boolean;
    updatedAt: Date;
    resolvedAt: Date | null;
}

export async function updateComplaint(client: Client, args: UpdateComplaintArgs): Promise<void> {
    await client.query({
        text: updateComplaintQuery,
        values: [args.id, args.status, args.assigneeId, args.resolution, args.verified, args.updatedAt, args.resolvedAt],
        rowMode: "array"
    });
}

export const listComplaintsQuery = `-- name: ListComplaints :many
SELECT id, ticket_number, booking_id, reporter_id, reporter_role, against_id, reason, description, photo_media_ids, status, assignee_id, resolution, verified, created_at, updated_at, resolved_at FROM admin.complaints
WHERE ($1::text IS NULL OR status = $1::text)
  AND ($2::uuid IS NULL OR assignee_id = $2::uuid)
  AND ($3::timestamptz IS NULL OR (created_at, id) < ($3::timestamptz, $4::uuid))
ORDER BY created_at DESC, id DESC
LIMIT $5`;

export interface ListComplaintsArgs {
    status: string | null;
    assigneeId: string | null;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface ListComplaintsRow {
    id: string;
    ticketNumber: string;
    bookingId: string;
    reporterId: string;
    reporterRole: string;
    againstId: string;
    reason: string;
    description: string;
    photoMediaIds: string[];
    status: string;
    assigneeId: string | null;
    resolution: string;
    verified: boolean;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt: Date | null;
}

export async function listComplaints(client: Client, args: ListComplaintsArgs): Promise<ListComplaintsRow[]> {
    const result = await client.query({
        text: listComplaintsQuery,
        values: [args.status, args.assigneeId, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            ticketNumber: row[1],
            bookingId: row[2],
            reporterId: row[3],
            reporterRole: row[4],
            againstId: row[5],
            reason: row[6],
            description: row[7],
            photoMediaIds: row[8],
            status: row[9],
            assigneeId: row[10],
            resolution: row[11],
            verified: row[12],
            createdAt: row[13],
            updatedAt: row[14],
            resolvedAt: row[15]
        };
    });
}

export const insertCommentQuery = `-- name: InsertComment :exec
INSERT INTO admin.complaint_comments (id, complaint_id, author_id, body, at) VALUES ($1, $2, $3, $4, $5)`;

export interface InsertCommentArgs {
    id: string;
    complaintId: string;
    authorId: string;
    body: string;
    at: Date;
}

export async function insertComment(client: Client, args: InsertCommentArgs): Promise<void> {
    await client.query({
        text: insertCommentQuery,
        values: [args.id, args.complaintId, args.authorId, args.body, args.at],
        rowMode: "array"
    });
}

export const listCommentsQuery = `-- name: ListComments :many
SELECT id, complaint_id, author_id, body, at FROM admin.complaint_comments WHERE complaint_id = $1 ORDER BY at, id`;

export interface ListCommentsArgs {
    complaintId: string;
}

export interface ListCommentsRow {
    id: string;
    complaintId: string;
    authorId: string;
    body: string;
    at: Date;
}

export async function listComments(client: Client, args: ListCommentsArgs): Promise<ListCommentsRow[]> {
    const result = await client.query({
        text: listCommentsQuery,
        values: [args.complaintId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            complaintId: row[1],
            authorId: row[2],
            body: row[3],
            at: row[4]
        };
    });
}

export const addStatsProviderQuery = `-- name: AddStatsProvider :exec
INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ($1, 'active', 0) ON CONFLICT DO NOTHING`;

export interface AddStatsProviderArgs {
    providerId: string;
}

export async function addStatsProvider(client: Client, args: AddStatsProviderArgs): Promise<void> {
    await client.query({
        text: addStatsProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const setStatsLevelQuery = `-- name: SetStatsLevel :exec
INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ($1, 'active', $2)
ON CONFLICT (provider_id) DO UPDATE SET level = EXCLUDED.level`;

export interface SetStatsLevelArgs {
    providerId: string;
    level: number;
}

export async function setStatsLevel(client: Client, args: SetStatsLevelArgs): Promise<void> {
    await client.query({
        text: setStatsLevelQuery,
        values: [args.providerId, args.level],
        rowMode: "array"
    });
}

export const setStatsStatusQuery = `-- name: SetStatsStatus :exec
INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ($1, $2, 0)
ON CONFLICT (provider_id) DO UPDATE SET status = EXCLUDED.status`;

export interface SetStatsStatusArgs {
    providerId: string;
    status: string;
}

export async function setStatsStatus(client: Client, args: SetStatsStatusArgs): Promise<void> {
    await client.query({
        text: setStatsStatusQuery,
        values: [args.providerId, args.status],
        rowMode: "array"
    });
}

export const deleteStatsProviderQuery = `-- name: DeleteStatsProvider :exec
DELETE FROM admin.stats_providers WHERE provider_id = $1`;

export interface DeleteStatsProviderArgs {
    providerId: string;
}

export async function deleteStatsProvider(client: Client, args: DeleteStatsProviderArgs): Promise<void> {
    await client.query({
        text: deleteStatsProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const bumpBookingsQuery = `-- name: BumpBookings :exec
INSERT INTO admin.stats_bookings_daily (day, requested, completed) VALUES ($1, $2, $3)
ON CONFLICT (day) DO UPDATE SET requested = admin.stats_bookings_daily.requested + EXCLUDED.requested,
    completed = admin.stats_bookings_daily.completed + EXCLUDED.completed`;

export interface BumpBookingsArgs {
    day: Date;
    requested: number;
    completed: number;
}

export async function bumpBookings(client: Client, args: BumpBookingsArgs): Promise<void> {
    await client.query({
        text: bumpBookingsQuery,
        values: [args.day, args.requested, args.completed],
        rowMode: "array"
    });
}

export const providersByStatusQuery = `-- name: ProvidersByStatus :many
SELECT (CASE WHEN status = 'active' AND level = 0 THEN 'pending' ELSE status END)::text AS status, count(*) AS n
FROM admin.stats_providers GROUP BY 1`;

export interface ProvidersByStatusRow {
    status: string;
    n: string;
}

export async function providersByStatus(client: Client): Promise<ProvidersByStatusRow[]> {
    const result = await client.query({
        text: providersByStatusQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            status: row[0],
            n: row[1]
        };
    });
}

export const providersByLevelQuery = `-- name: ProvidersByLevel :many
SELECT level, count(*) AS n FROM admin.stats_providers GROUP BY level`;

export interface ProvidersByLevelRow {
    level: number;
    n: string;
}

export async function providersByLevel(client: Client): Promise<ProvidersByLevelRow[]> {
    const result = await client.query({
        text: providersByLevelQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            level: row[0],
            n: row[1]
        };
    });
}

export const bookingsSinceQuery = `-- name: BookingsSince :many
SELECT day, requested, completed FROM admin.stats_bookings_daily WHERE day >= $1 ORDER BY day`;

export interface BookingsSinceArgs {
    day: Date;
}

export interface BookingsSinceRow {
    day: Date;
    requested: number;
    completed: number;
}

export async function bookingsSince(client: Client, args: BookingsSinceArgs): Promise<BookingsSinceRow[]> {
    const result = await client.query({
        text: bookingsSinceQuery,
        values: [args.day],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            day: row[0],
            requested: row[1],
            completed: row[2]
        };
    });
}

export const countOpenComplaintsQuery = `-- name: CountOpenComplaints :one
SELECT count(*) FROM admin.complaints WHERE status <> 'resolved'`;

export interface CountOpenComplaintsRow {
    count: string;
}

export async function countOpenComplaints(client: Client): Promise<CountOpenComplaintsRow | null> {
    const result = await client.query({
        text: countOpenComplaintsQuery,
        values: [],
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

export const countComplaintsAgainstQuery = `-- name: CountComplaintsAgainst :one
SELECT count(*) FROM admin.complaints WHERE against_id = $1`;

export interface CountComplaintsAgainstArgs {
    againstId: string;
}

export interface CountComplaintsAgainstRow {
    count: string;
}

export async function countComplaintsAgainst(client: Client, args: CountComplaintsAgainstArgs): Promise<CountComplaintsAgainstRow | null> {
    const result = await client.query({
        text: countComplaintsAgainstQuery,
        values: [args.againstId],
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

export const complaintsInvolvingQuery = `-- name: ComplaintsInvolving :many
SELECT id, ticket_number, booking_id, reporter_id, reporter_role, against_id, reason, description, photo_media_ids, status, assignee_id, resolution, verified, created_at, updated_at, resolved_at FROM admin.complaints WHERE reporter_id = $1 OR against_id = $1 ORDER BY created_at DESC, id DESC LIMIT $2`;

export interface ComplaintsInvolvingArgs {
    reporterId: string;
    limit: string;
}

export interface ComplaintsInvolvingRow {
    id: string;
    ticketNumber: string;
    bookingId: string;
    reporterId: string;
    reporterRole: string;
    againstId: string;
    reason: string;
    description: string;
    photoMediaIds: string[];
    status: string;
    assigneeId: string | null;
    resolution: string;
    verified: boolean;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt: Date | null;
}

export async function complaintsInvolving(client: Client, args: ComplaintsInvolvingArgs): Promise<ComplaintsInvolvingRow[]> {
    const result = await client.query({
        text: complaintsInvolvingQuery,
        values: [args.reporterId, args.limit],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            ticketNumber: row[1],
            bookingId: row[2],
            reporterId: row[3],
            reporterRole: row[4],
            againstId: row[5],
            reason: row[6],
            description: row[7],
            photoMediaIds: row[8],
            status: row[9],
            assigneeId: row[10],
            resolution: row[11],
            verified: row[12],
            createdAt: row[13],
            updatedAt: row[14],
            resolvedAt: row[15]
        };
    });
}

