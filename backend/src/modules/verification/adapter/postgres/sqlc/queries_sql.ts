import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const ensureLevelQuery = `-- name: EnsureLevel :exec
INSERT INTO verification.levels (provider_id) VALUES ($1) ON CONFLICT DO NOTHING`;

export interface EnsureLevelArgs {
    providerId: string;
}

export async function ensureLevel(client: Client, args: EnsureLevelArgs): Promise<void> {
    await client.query({
        text: ensureLevelQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const lockLevelQuery = `-- name: LockLevel :one
SELECT provider_id, level, level2_passed_at, blocked, service_ids, submitted_at
FROM verification.levels WHERE provider_id = $1 FOR UPDATE`;

export interface LockLevelArgs {
    providerId: string;
}

export interface LockLevelRow {
    providerId: string;
    level: number;
    level2PassedAt: Date | null;
    blocked: boolean;
    serviceIds: string[];
    submittedAt: Date | null;
}

export async function lockLevel(client: Client, args: LockLevelArgs): Promise<LockLevelRow | null> {
    const result = await client.query({
        text: lockLevelQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        providerId: row[0],
        level: row[1],
        level2PassedAt: row[2],
        blocked: row[3],
        serviceIds: row[4],
        submittedAt: row[5]
    };
}

export const levelByProviderQuery = `-- name: LevelByProvider :one
SELECT provider_id, level, level2_passed_at, blocked, service_ids, submitted_at
FROM verification.levels WHERE provider_id = $1`;

export interface LevelByProviderArgs {
    providerId: string;
}

export interface LevelByProviderRow {
    providerId: string;
    level: number;
    level2PassedAt: Date | null;
    blocked: boolean;
    serviceIds: string[];
    submittedAt: Date | null;
}

export async function levelByProvider(client: Client, args: LevelByProviderArgs): Promise<LevelByProviderRow | null> {
    const result = await client.query({
        text: levelByProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        providerId: row[0],
        level: row[1],
        level2PassedAt: row[2],
        blocked: row[3],
        serviceIds: row[4],
        submittedAt: row[5]
    };
}

export const saveLevelQuery = `-- name: SaveLevel :exec
UPDATE verification.levels SET level = $2, level2_passed_at = $3, blocked = $4, service_ids = $5, submitted_at = $6, updated_at = $7
WHERE provider_id = $1`;

export interface SaveLevelArgs {
    providerId: string;
    level: number;
    level2PassedAt: Date | null;
    blocked: boolean;
    serviceIds: string[];
    submittedAt: Date | null;
    updatedAt: Date;
}

export async function saveLevel(client: Client, args: SaveLevelArgs): Promise<void> {
    await client.query({
        text: saveLevelQuery,
        values: [args.providerId, args.level, args.level2PassedAt, args.blocked, args.serviceIds, args.submittedAt, args.updatedAt],
        rowMode: "array"
    });
}

export const itemsByProviderQuery = `-- name: ItemsByProvider :many
SELECT item_type, status, rejection_reason, fields, submitted_at, decided_at, decided_by, expires_at
FROM verification.items WHERE provider_id = $1`;

export interface ItemsByProviderArgs {
    providerId: string;
}

export interface ItemsByProviderRow {
    itemType: string;
    status: string;
    rejectionReason: string;
    fields: any;
    submittedAt: Date | null;
    decidedAt: Date | null;
    decidedBy: string | null;
    expiresAt: Date | null;
}

export async function itemsByProvider(client: Client, args: ItemsByProviderArgs): Promise<ItemsByProviderRow[]> {
    const result = await client.query({
        text: itemsByProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            itemType: row[0],
            status: row[1],
            rejectionReason: row[2],
            fields: row[3],
            submittedAt: row[4],
            decidedAt: row[5],
            decidedBy: row[6],
            expiresAt: row[7]
        };
    });
}

export const upsertItemQuery = `-- name: UpsertItem :exec
INSERT INTO verification.items (provider_id, item_type, status, rejection_reason, fields, submitted_at, decided_at, decided_by, expires_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
ON CONFLICT (provider_id, item_type) DO UPDATE SET status = excluded.status, rejection_reason = excluded.rejection_reason,
    fields = excluded.fields, submitted_at = excluded.submitted_at, decided_at = excluded.decided_at,
    decided_by = excluded.decided_by, expires_at = excluded.expires_at`;

export interface UpsertItemArgs {
    providerId: string;
    itemType: string;
    status: string;
    rejectionReason: string;
    fields: any;
    submittedAt: Date | null;
    decidedAt: Date | null;
    decidedBy: string | null;
    expiresAt: Date | null;
}

export async function upsertItem(client: Client, args: UpsertItemArgs): Promise<void> {
    await client.query({
        text: upsertItemQuery,
        values: [args.providerId, args.itemType, args.status, args.rejectionReason, args.fields, args.submittedAt, args.decidedAt, args.decidedBy, args.expiresAt],
        rowMode: "array"
    });
}

export const currentDocumentsQuery = `-- name: CurrentDocuments :many
SELECT id, item_type, kind, media_id, created_at FROM verification.documents
WHERE provider_id = $1 AND current ORDER BY created_at, id`;

export interface CurrentDocumentsArgs {
    providerId: string;
}

export interface CurrentDocumentsRow {
    id: string;
    itemType: string;
    kind: string;
    mediaId: string;
    createdAt: Date;
}

export async function currentDocuments(client: Client, args: CurrentDocumentsArgs): Promise<CurrentDocumentsRow[]> {
    const result = await client.query({
        text: currentDocumentsQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            itemType: row[1],
            kind: row[2],
            mediaId: row[3],
            createdAt: row[4]
        };
    });
}

export const retireDocumentsQuery = `-- name: RetireDocuments :exec
UPDATE verification.documents SET current = false WHERE provider_id = $1 AND item_type = ANY($2::text[])`;

export interface RetireDocumentsArgs {
    providerId: string;
    itemTypes: string[];
}

export async function retireDocuments(client: Client, args: RetireDocumentsArgs): Promise<void> {
    await client.query({
        text: retireDocumentsQuery,
        values: [args.providerId, args.itemTypes],
        rowMode: "array"
    });
}

export const insertDocumentQuery = `-- name: InsertDocument :exec
INSERT INTO verification.documents (id, provider_id, item_type, kind, media_id, created_at) VALUES ($1, $2, $3, $4, $5, $6)`;

export interface InsertDocumentArgs {
    id: string;
    providerId: string;
    itemType: string;
    kind: string;
    mediaId: string;
    createdAt: Date;
}

export async function insertDocument(client: Client, args: InsertDocumentArgs): Promise<void> {
    await client.query({
        text: insertDocumentQuery,
        values: [args.id, args.providerId, args.itemType, args.kind, args.mediaId, args.createdAt],
        rowMode: "array"
    });
}

export const nIDByProviderQuery = `-- name: NIDByProvider :one
SELECT nid_ciphertext, nid_hash FROM verification.nid_records WHERE provider_id = $1`;

export interface NIDByProviderArgs {
    providerId: string;
}

export interface NIDByProviderRow {
    nidCiphertext: Buffer;
    nidHash: string;
}

export async function nIDByProvider(client: Client, args: NIDByProviderArgs): Promise<NIDByProviderRow | null> {
    const result = await client.query({
        text: nIDByProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        nidCiphertext: row[0],
        nidHash: row[1]
    };
}

export const upsertNIDQuery = `-- name: UpsertNID :exec
INSERT INTO verification.nid_records (provider_id, nid_ciphertext, nid_hash, updated_at) VALUES ($1, $2, $3, $4)
ON CONFLICT (provider_id) DO UPDATE SET nid_ciphertext = excluded.nid_ciphertext, nid_hash = excluded.nid_hash, updated_at = excluded.updated_at`;

export interface UpsertNIDArgs {
    providerId: string;
    nidCiphertext: Buffer;
    nidHash: string;
    updatedAt: Date;
}

export async function upsertNID(client: Client, args: UpsertNIDArgs): Promise<void> {
    await client.query({
        text: upsertNIDQuery,
        values: [args.providerId, args.nidCiphertext, args.nidHash, args.updatedAt],
        rowMode: "array"
    });
}

export const nIDBlockedQuery = `-- name: NIDBlocked :one
SELECT EXISTS (SELECT 1 FROM verification.blocked_nids WHERE nid_hash = $1)`;

export interface NIDBlockedArgs {
    nidHash: string;
}

export interface NIDBlockedRow {
    exists: boolean;
}

export async function nIDBlocked(client: Client, args: NIDBlockedArgs): Promise<NIDBlockedRow | null> {
    const result = await client.query({
        text: nIDBlockedQuery,
        values: [args.nidHash],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        exists: row[0]
    };
}

export const blockNIDQuery = `-- name: BlockNID :exec
INSERT INTO verification.blocked_nids (nid_hash, reason)
SELECT nid_hash, $1 FROM verification.nid_records WHERE provider_id = $2
ON CONFLICT DO NOTHING`;

export interface BlockNIDArgs {
    reason: string;
    providerId: string;
}

export async function blockNID(client: Client, args: BlockNIDArgs): Promise<void> {
    await client.query({
        text: blockNIDQuery,
        values: [args.reason, args.providerId],
        rowMode: "array"
    });
}

export const sessionsByProviderQuery = `-- name: SessionsByProvider :many
SELECT id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes, visit_lat, visit_lng,
    photo_media_ids, decided_by, decided_at, created_at
FROM verification.level2_sessions WHERE provider_id = $1 ORDER BY created_at, id`;

export interface SessionsByProviderArgs {
    providerId: string;
}

export interface SessionsByProviderRow {
    id: string;
    providerId: string;
    serviceId: string;
    scheduledAt: Date;
    location: string;
    status: string;
    result: string | null;
    checklist: any;
    notes: string;
    visitLat: number | null;
    visitLng: number | null;
    photoMediaIds: string[];
    decidedBy: string | null;
    decidedAt: Date | null;
    createdAt: Date;
}

export async function sessionsByProvider(client: Client, args: SessionsByProviderArgs): Promise<SessionsByProviderRow[]> {
    const result = await client.query({
        text: sessionsByProviderQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            providerId: row[1],
            serviceId: row[2],
            scheduledAt: row[3],
            location: row[4],
            status: row[5],
            result: row[6],
            checklist: row[7],
            notes: row[8],
            visitLat: row[9],
            visitLng: row[10],
            photoMediaIds: row[11],
            decidedBy: row[12],
            decidedAt: row[13],
            createdAt: row[14]
        };
    });
}

export const sessionByIDQuery = `-- name: SessionByID :one
SELECT id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes, visit_lat, visit_lng,
    photo_media_ids, decided_by, decided_at, created_at
FROM verification.level2_sessions WHERE id = $1`;

export interface SessionByIDArgs {
    id: string;
}

export interface SessionByIDRow {
    id: string;
    providerId: string;
    serviceId: string;
    scheduledAt: Date;
    location: string;
    status: string;
    result: string | null;
    checklist: any;
    notes: string;
    visitLat: number | null;
    visitLng: number | null;
    photoMediaIds: string[];
    decidedBy: string | null;
    decidedAt: Date | null;
    createdAt: Date;
}

export async function sessionByID(client: Client, args: SessionByIDArgs): Promise<SessionByIDRow | null> {
    const result = await client.query({
        text: sessionByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        providerId: row[1],
        serviceId: row[2],
        scheduledAt: row[3],
        location: row[4],
        status: row[5],
        result: row[6],
        checklist: row[7],
        notes: row[8],
        visitLat: row[9],
        visitLng: row[10],
        photoMediaIds: row[11],
        decidedBy: row[12],
        decidedAt: row[13],
        createdAt: row[14]
    };
}

export const listSessionsQuery = `-- name: ListSessions :many
SELECT id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes, visit_lat, visit_lng,
    photo_media_ids, decided_by, decided_at, created_at
FROM verification.level2_sessions
WHERE ($1::uuid IS NULL OR provider_id = $1)
  AND ($2::text IS NULL OR status = $2)
  AND ($3::timestamptz IS NULL OR (created_at, id) < ($3, $4::uuid))
ORDER BY created_at DESC, id DESC LIMIT $5`;

export interface ListSessionsArgs {
    providerId: string | null;
    status: string | null;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface ListSessionsRow {
    id: string;
    providerId: string;
    serviceId: string;
    scheduledAt: Date;
    location: string;
    status: string;
    result: string | null;
    checklist: any;
    notes: string;
    visitLat: number | null;
    visitLng: number | null;
    photoMediaIds: string[];
    decidedBy: string | null;
    decidedAt: Date | null;
    createdAt: Date;
}

export async function listSessions(client: Client, args: ListSessionsArgs): Promise<ListSessionsRow[]> {
    const result = await client.query({
        text: listSessionsQuery,
        values: [args.providerId, args.status, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            providerId: row[1],
            serviceId: row[2],
            scheduledAt: row[3],
            location: row[4],
            status: row[5],
            result: row[6],
            checklist: row[7],
            notes: row[8],
            visitLat: row[9],
            visitLng: row[10],
            photoMediaIds: row[11],
            decidedBy: row[12],
            decidedAt: row[13],
            createdAt: row[14]
        };
    });
}

export const upsertSessionQuery = `-- name: UpsertSession :exec
INSERT INTO verification.level2_sessions (id, provider_id, service_id, scheduled_at, location, status, result, checklist, notes,
    visit_lat, visit_lng, photo_media_ids, decided_by, decided_at, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
ON CONFLICT (id) DO UPDATE SET status = excluded.status, result = excluded.result, checklist = excluded.checklist,
    notes = excluded.notes, visit_lat = excluded.visit_lat, visit_lng = excluded.visit_lng,
    photo_media_ids = excluded.photo_media_ids, decided_by = excluded.decided_by, decided_at = excluded.decided_at`;

export interface UpsertSessionArgs {
    id: string;
    providerId: string;
    serviceId: string;
    scheduledAt: Date;
    location: string;
    status: string;
    result: string | null;
    checklist: any;
    notes: string;
    visitLat: number | null;
    visitLng: number | null;
    photoMediaIds: string[];
    decidedBy: string | null;
    decidedAt: Date | null;
    createdAt: Date;
}

export async function upsertSession(client: Client, args: UpsertSessionArgs): Promise<void> {
    await client.query({
        text: upsertSessionQuery,
        values: [args.id, args.providerId, args.serviceId, args.scheduledAt, args.location, args.status, args.result, args.checklist, args.notes, args.visitLat, args.visitLng, args.photoMediaIds, args.decidedBy, args.decidedAt, args.createdAt],
        rowMode: "array"
    });
}

export const levelsQuery = `-- name: Levels :many
SELECT provider_id, level FROM verification.levels WHERE provider_id = ANY($1::uuid[])`;

export interface LevelsArgs {
    ids: string[];
}

export interface LevelsRow {
    providerId: string;
    level: number;
}

export async function levels(client: Client, args: LevelsArgs): Promise<LevelsRow[]> {
    const result = await client.query({
        text: levelsQuery,
        values: [args.ids],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            providerId: row[0],
            level: row[1]
        };
    });
}

export const queueQuery = `-- name: Queue :many
SELECT l.provider_id, l.submitted_at::timestamptz AS submitted_at, l.service_ids,
    array_agg(i.item_type ORDER BY i.item_type)::text[] AS pending_items
FROM verification.levels l
JOIN verification.items i ON i.provider_id = l.provider_id AND i.status = 'pending'
WHERE l.submitted_at IS NOT NULL
  AND ($1::uuid IS NULL OR $1 = ANY(l.service_ids))
  AND ($2::timestamptz IS NULL OR (l.submitted_at, l.provider_id) > ($2, $3::uuid))
GROUP BY l.provider_id, l.submitted_at, l.service_ids
HAVING $4::text IS NULL OR $4 = ANY(array_agg(i.item_type))
ORDER BY l.submitted_at, l.provider_id LIMIT $5`;

export interface QueueArgs {
    serviceId: string | null;
    afterAt: Date | null;
    afterId: string;
    itemType: string | null;
    maxRows: string;
}

export interface QueueRow {
    providerId: string;
    submittedAt: Date;
    serviceIds: string[];
    pendingItems: string[];
}

export async function queue(client: Client, args: QueueArgs): Promise<QueueRow[]> {
    const result = await client.query({
        text: queueQuery,
        values: [args.serviceId, args.afterAt, args.afterId, args.itemType, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            providerId: row[0],
            submittedAt: row[1],
            serviceIds: row[2],
            pendingItems: row[3]
        };
    });
}

export const expiredByQuery = `-- name: ExpiredBy :many
SELECT DISTINCT provider_id FROM verification.items WHERE status = 'approved' AND expires_at <= $1`;

export interface ExpiredByArgs {
    expiresAt: Date | null;
}

export interface ExpiredByRow {
    providerId: string;
}

export async function expiredBy(client: Client, args: ExpiredByArgs): Promise<ExpiredByRow[]> {
    const result = await client.query({
        text: expiredByQuery,
        values: [args.expiresAt],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            providerId: row[0]
        };
    });
}

export const expiringBetweenQuery = `-- name: ExpiringBetween :many
SELECT provider_id, item_type, expires_at::timestamptz AS expires_at FROM verification.items
WHERE status = 'approved' AND expires_at > $1 AND expires_at <= $2 ORDER BY expires_at`;

export interface ExpiringBetweenArgs {
    afterAt: Date | null;
    untilAt: Date | null;
}

export interface ExpiringBetweenRow {
    providerId: string;
    itemType: string;
    expiresAt: Date;
}

export async function expiringBetween(client: Client, args: ExpiringBetweenArgs): Promise<ExpiringBetweenRow[]> {
    const result = await client.query({
        text: expiringBetweenQuery,
        values: [args.afterAt, args.untilAt],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            providerId: row[0],
            itemType: row[1],
            expiresAt: row[2]
        };
    });
}

export const recordReminderQuery = `-- name: RecordReminder :execrows
INSERT INTO verification.reminders_sent (provider_id, item_type, expires_at, days_before, sent_at) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT DO NOTHING`;

export interface RecordReminderArgs {
    providerId: string;
    itemType: string;
    expiresAt: Date;
    daysBefore: number;
    sentAt: Date;
}

export const countPendingReviewsQuery = `-- name: CountPendingReviews :one
SELECT count(DISTINCT l.provider_id) FROM verification.levels l
JOIN verification.items i ON i.provider_id = l.provider_id AND i.status = 'pending'
WHERE l.submitted_at IS NOT NULL`;

export interface CountPendingReviewsRow {
    count: string;
}

export async function countPendingReviews(client: Client): Promise<CountPendingReviewsRow | null> {
    const result = await client.query({
        text: countPendingReviewsQuery,
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

export const recordClosureQuery = `-- name: RecordClosure :exec
INSERT INTO verification.closed_accounts (provider_id, closed_at) VALUES ($1, $2)
ON CONFLICT (provider_id) DO NOTHING`;

export interface RecordClosureArgs {
    providerId: string;
    closedAt: Date;
}

export async function recordClosure(client: Client, args: RecordClosureArgs): Promise<void> {
    await client.query({
        text: recordClosureQuery,
        values: [args.providerId, args.closedAt],
        rowMode: "array"
    });
}

export const closedBeforeQuery = `-- name: ClosedBefore :many
SELECT provider_id FROM verification.closed_accounts WHERE closed_at < $1
ORDER BY closed_at LIMIT 500`;

export interface ClosedBeforeArgs {
    closedAt: Date;
}

export interface ClosedBeforeRow {
    providerId: string;
}

export async function closedBefore(client: Client, args: ClosedBeforeArgs): Promise<ClosedBeforeRow[]> {
    const result = await client.query({
        text: closedBeforeQuery,
        values: [args.closedAt],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            providerId: row[0]
        };
    });
}

export const level2PhotosQuery = `-- name: Level2Photos :many
SELECT unnest(photo_media_ids)::uuid AS media_id FROM verification.level2_sessions
WHERE provider_id = $1`;

export interface Level2PhotosArgs {
    providerId: string;
}

export interface Level2PhotosRow {
    mediaId: string;
}

export async function level2Photos(client: Client, args: Level2PhotosArgs): Promise<Level2PhotosRow[]> {
    const result = await client.query({
        text: level2PhotosQuery,
        values: [args.providerId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            mediaId: row[0]
        };
    });
}

export const purgeItemsQuery = `-- name: PurgeItems :exec
DELETE FROM verification.items WHERE provider_id = $1`;

export interface PurgeItemsArgs {
    providerId: string;
}

export async function purgeItems(client: Client, args: PurgeItemsArgs): Promise<void> {
    await client.query({
        text: purgeItemsQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const purgeDocumentsQuery = `-- name: PurgeDocuments :exec
DELETE FROM verification.documents WHERE provider_id = $1`;

export interface PurgeDocumentsArgs {
    providerId: string;
}

export async function purgeDocuments(client: Client, args: PurgeDocumentsArgs): Promise<void> {
    await client.query({
        text: purgeDocumentsQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const purgeNidQuery = `-- name: PurgeNid :exec
DELETE FROM verification.nid_records WHERE provider_id = $1`;

export interface PurgeNidArgs {
    providerId: string;
}

export async function purgeNid(client: Client, args: PurgeNidArgs): Promise<void> {
    await client.query({
        text: purgeNidQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const purgeLevelQuery = `-- name: PurgeLevel :exec
DELETE FROM verification.levels WHERE provider_id = $1`;

export interface PurgeLevelArgs {
    providerId: string;
}

export async function purgeLevel(client: Client, args: PurgeLevelArgs): Promise<void> {
    await client.query({
        text: purgeLevelQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const purgeLevel2SessionsQuery = `-- name: PurgeLevel2Sessions :exec
DELETE FROM verification.level2_sessions WHERE provider_id = $1`;

export interface PurgeLevel2SessionsArgs {
    providerId: string;
}

export async function purgeLevel2Sessions(client: Client, args: PurgeLevel2SessionsArgs): Promise<void> {
    await client.query({
        text: purgeLevel2SessionsQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const purgeRemindersQuery = `-- name: PurgeReminders :exec
DELETE FROM verification.reminders_sent WHERE provider_id = $1`;

export interface PurgeRemindersArgs {
    providerId: string;
}

export async function purgeReminders(client: Client, args: PurgeRemindersArgs): Promise<void> {
    await client.query({
        text: purgeRemindersQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const purgeClosureQuery = `-- name: PurgeClosure :exec
DELETE FROM verification.closed_accounts WHERE provider_id = $1`;

export interface PurgeClosureArgs {
    providerId: string;
}

export async function purgeClosure(client: Client, args: PurgeClosureArgs): Promise<void> {
    await client.query({
        text: purgeClosureQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

