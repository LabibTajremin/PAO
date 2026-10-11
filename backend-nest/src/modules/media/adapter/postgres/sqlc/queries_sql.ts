import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const createObjectQuery = `-- name: CreateObject :exec
INSERT INTO media.objects (id, owner_id, purpose, content_type, size_bytes, bucket, object_key, status, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', $8)`;

export interface CreateObjectArgs {
    id: string;
    ownerId: string;
    purpose: string;
    contentType: string;
    sizeBytes: string;
    bucket: string;
    objectKey: string;
    createdAt: Date;
}

export async function createObject(client: Client, args: CreateObjectArgs): Promise<void> {
    await client.query({
        text: createObjectQuery,
        values: [args.id, args.ownerId, args.purpose, args.contentType, args.sizeBytes, args.bucket, args.objectKey, args.createdAt],
        rowMode: "array"
    });
}

export const objectByIDQuery = `-- name: ObjectByID :one
SELECT id, owner_id, purpose, content_type, size_bytes, bucket, object_key, status, attached, created_at
FROM media.objects WHERE id = $1`;

export interface ObjectByIDArgs {
    id: string;
}

export interface ObjectByIDRow {
    id: string;
    ownerId: string;
    purpose: string;
    contentType: string;
    sizeBytes: string;
    bucket: string;
    objectKey: string;
    status: string;
    attached: boolean;
    createdAt: Date;
}

export async function objectByID(client: Client, args: ObjectByIDArgs): Promise<ObjectByIDRow | null> {
    const result = await client.query({
        text: objectByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        ownerId: row[1],
        purpose: row[2],
        contentType: row[3],
        sizeBytes: row[4],
        bucket: row[5],
        objectKey: row[6],
        status: row[7],
        attached: row[8],
        createdAt: row[9]
    };
}

export const markConfirmedQuery = `-- name: MarkConfirmed :exec
UPDATE media.objects SET status = 'confirmed', confirmed_at = $2 WHERE id = $1`;

export interface MarkConfirmedArgs {
    id: string;
    confirmedAt: Date | null;
}

export async function markConfirmed(client: Client, args: MarkConfirmedArgs): Promise<void> {
    await client.query({
        text: markConfirmedQuery,
        values: [args.id, args.confirmedAt],
        rowMode: "array"
    });
}

export const markAttachedQuery = `-- name: MarkAttached :execrows
UPDATE media.objects SET attached = true WHERE id = $1`;

export interface MarkAttachedArgs {
    id: string;
}

export const deleteObjectQuery = `-- name: DeleteObject :exec
DELETE FROM media.objects WHERE id = $1`;

export interface DeleteObjectArgs {
    id: string;
}

export async function deleteObject(client: Client, args: DeleteObjectArgs): Promise<void> {
    await client.query({
        text: deleteObjectQuery,
        values: [args.id],
        rowMode: "array"
    });
}

export const orphansQuery = `-- name: Orphans :many
SELECT id, owner_id, purpose, content_type, size_bytes, bucket, object_key, status, attached, created_at
FROM media.objects WHERE NOT attached AND created_at < $1 ORDER BY created_at LIMIT 500`;

export interface OrphansArgs {
    createdAt: Date;
}

export interface OrphansRow {
    id: string;
    ownerId: string;
    purpose: string;
    contentType: string;
    sizeBytes: string;
    bucket: string;
    objectKey: string;
    status: string;
    attached: boolean;
    createdAt: Date;
}

export async function orphans(client: Client, args: OrphansArgs): Promise<OrphansRow[]> {
    const result = await client.query({
        text: orphansQuery,
        values: [args.createdAt],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            ownerId: row[1],
            purpose: row[2],
            contentType: row[3],
            sizeBytes: row[4],
            bucket: row[5],
            objectKey: row[6],
            status: row[7],
            attached: row[8],
            createdAt: row[9]
        };
    });
}

