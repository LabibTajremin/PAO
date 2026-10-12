import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const appendEntryQuery = `-- name: AppendEntry :exec
INSERT INTO audit.entries (id, at, actor_id, actor_role, action, subject_type, subject_id, reason, before, after, event_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (event_id) DO NOTHING`;

export interface AppendEntryArgs {
    id: string;
    at: Date;
    actorId: string | null;
    actorRole: string;
    action: string;
    subjectType: string;
    subjectId: string;
    reason: string;
    before: any | null;
    after: any | null;
    eventId: string | null;
}

export async function appendEntry(client: Client, args: AppendEntryArgs): Promise<void> {
    await client.query({
        text: appendEntryQuery,
        values: [args.id, args.at, args.actorId, args.actorRole, args.action, args.subjectType, args.subjectId, args.reason, args.before, args.after, args.eventId],
        rowMode: "array"
    });
}

export const listQuery = `-- name: List :many
SELECT id, at, actor_id, actor_role, action, subject_type, subject_id, reason, before, after
FROM audit.entries
WHERE ($1::uuid IS NULL OR actor_id = $1)
  AND ($2::text IS NULL OR action = $2)
  AND ($3::text IS NULL OR subject_type = $3)
  AND ($4::text IS NULL OR subject_id = $4)
  AND ($5::timestamptz IS NULL OR at >= $5)
  AND ($6::timestamptz IS NULL OR at <= $6)
  AND ($7::timestamptz IS NULL OR (at, id) < ($7, $8::uuid))
ORDER BY at DESC, id DESC
LIMIT $9`;

export interface ListArgs {
    actorId: string | null;
    action: string | null;
    subjectType: string | null;
    subjectId: string | null;
    fromAt: Date | null;
    toAt: Date | null;
    cursorAt: Date | null;
    cursorId: string | null;
    pageSize: string;
}

export interface ListRow {
    id: string;
    at: Date;
    actorId: string | null;
    actorRole: string;
    action: string;
    subjectType: string;
    subjectId: string;
    reason: string;
    before: any | null;
    after: any | null;
}

export async function list(client: Client, args: ListArgs): Promise<ListRow[]> {
    const result = await client.query({
        text: listQuery,
        values: [args.actorId, args.action, args.subjectType, args.subjectId, args.fromAt, args.toAt, args.cursorAt, args.cursorId, args.pageSize],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            at: row[1],
            actorId: row[2],
            actorRole: row[3],
            action: row[4],
            subjectType: row[5],
            subjectId: row[6],
            reason: row[7],
            before: row[8],
            after: row[9]
        };
    });
}

