import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const ensureProviderQuery = `-- name: EnsureProvider :exec
INSERT INTO provider.providers (id, phone, created_at, updated_at) VALUES ($1, $2, $3, $3)
ON CONFLICT (id) DO NOTHING`;

export interface EnsureProviderArgs {
    id: string;
    phone: string;
    createdAt: Date;
}

export async function ensureProvider(client: Client, args: EnsureProviderArgs): Promise<void> {
    await client.query({
        text: ensureProviderQuery,
        values: [args.id, args.phone, args.createdAt],
        rowMode: "array"
    });
}

export const providerByIDQuery = `-- name: ProviderByID :one
SELECT id, phone, full_name, date_of_birth, gender, present_address, permanent_address, bio, photo_media_id,
    experience_years, language, COALESCE(ST_Y(home_base::geometry), 0)::float8 AS home_lat, COALESCE(ST_X(home_base::geometry), 0)::float8 AS home_lng,
    (home_base IS NOT NULL)::bool AS has_home_base, working_radius_m, emergency_name, emergency_relation, emergency_phone,
    emergency_verified_at, coc_version, coc_accepted_at, steps_done, submitted_at, account_status, level,
    rating_avg, rating_count, completed_jobs, flagged_for_review, flag_reason, created_at,
    COALESCE((SELECT array_agg(s.service_id ORDER BY s.service_id) FROM provider.provider_services s WHERE s.provider_id = p.id), '{}')::uuid[] AS service_ids
FROM provider.providers p WHERE id = $1`;

export interface ProviderByIDArgs {
    id: string;
}

export interface ProviderByIDRow {
    id: string;
    phone: string;
    fullName: string;
    dateOfBirth: Date | null;
    gender: string | null;
    presentAddress: string;
    permanentAddress: string;
    bio: string;
    photoMediaId: string | null;
    experienceYears: number;
    language: string;
    homeLat: number;
    homeLng: number;
    hasHomeBase: boolean;
    workingRadiusM: number;
    emergencyName: string;
    emergencyRelation: string;
    emergencyPhone: string;
    emergencyVerifiedAt: Date | null;
    cocVersion: string;
    cocAcceptedAt: Date | null;
    stepsDone: string[];
    submittedAt: Date | null;
    accountStatus: string;
    level: number;
    ratingAvg: number;
    ratingCount: number;
    completedJobs: number;
    flaggedForReview: boolean;
    flagReason: string;
    createdAt: Date;
    serviceIds: string[];
}

export async function providerByID(client: Client, args: ProviderByIDArgs): Promise<ProviderByIDRow | null> {
    const result = await client.query({
        text: providerByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        phone: row[1],
        fullName: row[2],
        dateOfBirth: row[3],
        gender: row[4],
        presentAddress: row[5],
        permanentAddress: row[6],
        bio: row[7],
        photoMediaId: row[8],
        experienceYears: row[9],
        language: row[10],
        homeLat: row[11],
        homeLng: row[12],
        hasHomeBase: row[13],
        workingRadiusM: row[14],
        emergencyName: row[15],
        emergencyRelation: row[16],
        emergencyPhone: row[17],
        emergencyVerifiedAt: row[18],
        cocVersion: row[19],
        cocAcceptedAt: row[20],
        stepsDone: row[21],
        submittedAt: row[22],
        accountStatus: row[23],
        level: row[24],
        ratingAvg: row[25],
        ratingCount: row[26],
        completedJobs: row[27],
        flaggedForReview: row[28],
        flagReason: row[29],
        createdAt: row[30],
        serviceIds: row[31]
    };
}

export const saveProfileQuery = `-- name: SaveProfile :exec
UPDATE provider.providers SET full_name = $1, date_of_birth = $2, gender = $3,
    present_address = $4, permanent_address = $5, bio = $6,
    photo_media_id = $7, experience_years = $8, language = $9,
    home_base = CASE WHEN $10::bool
        THEN ST_SetSRID(ST_MakePoint($11::float8, $12::float8), 4326)::geography END,
    working_radius_m = $13, emergency_name = $14,
    emergency_relation = $15, emergency_phone = $16,
    emergency_verified_at = $17, coc_version = $18,
    coc_accepted_at = $19, steps_done = $20, submitted_at = $21,
    updated_at = $22
WHERE id = $23`;

export interface SaveProfileArgs {
    fullName: string;
    dateOfBirth: Date | null;
    gender: string | null;
    presentAddress: string;
    permanentAddress: string;
    bio: string;
    photoMediaId: string | null;
    experienceYears: number;
    language: string;
    hasHomeBase: boolean;
    homeLng: number;
    homeLat: number;
    workingRadiusM: number;
    emergencyName: string;
    emergencyRelation: string;
    emergencyPhone: string;
    emergencyVerifiedAt: Date | null;
    cocVersion: string;
    cocAcceptedAt: Date | null;
    stepsDone: string[];
    submittedAt: Date | null;
    updatedAt: Date;
    id: string;
}

export async function saveProfile(client: Client, args: SaveProfileArgs): Promise<void> {
    await client.query({
        text: saveProfileQuery,
        values: [args.fullName, args.dateOfBirth, args.gender, args.presentAddress, args.permanentAddress, args.bio, args.photoMediaId, args.experienceYears, args.language, args.hasHomeBase, args.homeLng, args.homeLat, args.workingRadiusM, args.emergencyName, args.emergencyRelation, args.emergencyPhone, args.emergencyVerifiedAt, args.cocVersion, args.cocAcceptedAt, args.stepsDone, args.submittedAt, args.updatedAt, args.id],
        rowMode: "array"
    });
}

export const clearServicesQuery = `-- name: ClearServices :exec
DELETE FROM provider.provider_services WHERE provider_id = $1`;

export interface ClearServicesArgs {
    providerId: string;
}

export async function clearServices(client: Client, args: ClearServicesArgs): Promise<void> {
    await client.query({
        text: clearServicesQuery,
        values: [args.providerId],
        rowMode: "array"
    });
}

export const addServiceQuery = `-- name: AddService :exec
INSERT INTO provider.provider_services (provider_id, service_id) VALUES ($1, $2)`;

export interface AddServiceArgs {
    providerId: string;
    serviceId: string;
}

export async function addService(client: Client, args: AddServiceArgs): Promise<void> {
    await client.query({
        text: addServiceQuery,
        values: [args.providerId, args.serviceId],
        rowMode: "array"
    });
}

export const candidatesQuery = `-- name: Candidates :many
SELECT id, full_name, photo_media_id, gender, level, rating_avg, rating_count, completed_jobs, working_radius_m
FROM provider.providers WHERE id = ANY($1::uuid[]) AND account_status = 'active' AND level >= $2`;

export interface CandidatesArgs {
    ids: string[];
    minLevel: number;
}

export interface CandidatesRow {
    id: string;
    fullName: string;
    photoMediaId: string | null;
    gender: string | null;
    level: number;
    ratingAvg: number;
    ratingCount: number;
    completedJobs: number;
    workingRadiusM: number;
}

export async function candidates(client: Client, args: CandidatesArgs): Promise<CandidatesRow[]> {
    const result = await client.query({
        text: candidatesQuery,
        values: [args.ids, args.minLevel],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            fullName: row[1],
            photoMediaId: row[2],
            gender: row[3],
            level: row[4],
            ratingAvg: row[5],
            ratingCount: row[6],
            completedJobs: row[7],
            workingRadiusM: row[8]
        };
    });
}

export const setLevelQuery = `-- name: SetLevel :exec
UPDATE provider.providers SET level = $2 WHERE id = $1`;

export interface SetLevelArgs {
    id: string;
    level: number;
}

export async function setLevel(client: Client, args: SetLevelArgs): Promise<void> {
    await client.query({
        text: setLevelQuery,
        values: [args.id, args.level],
        rowMode: "array"
    });
}

export const setAccountStatusQuery = `-- name: SetAccountStatus :exec
UPDATE provider.providers SET account_status = $2 WHERE id = $1`;

export interface SetAccountStatusArgs {
    id: string;
    accountStatus: string;
}

export async function setAccountStatus(client: Client, args: SetAccountStatusArgs): Promise<void> {
    await client.query({
        text: setAccountStatusQuery,
        values: [args.id, args.accountStatus],
        rowMode: "array"
    });
}

export const setRatingQuery = `-- name: SetRating :one
UPDATE provider.providers SET rating_avg = $2, rating_count = $3 WHERE id = $1 RETURNING completed_jobs`;

export interface SetRatingArgs {
    id: string;
    ratingAvg: number;
    ratingCount: number;
}

export interface SetRatingRow {
    completedJobs: number;
}

export async function setRating(client: Client, args: SetRatingArgs): Promise<SetRatingRow | null> {
    const result = await client.query({
        text: setRatingQuery,
        values: [args.id, args.ratingAvg, args.ratingCount],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        completedJobs: row[0]
    };
}

export const addCompletedJobQuery = `-- name: AddCompletedJob :exec
UPDATE provider.providers SET completed_jobs = completed_jobs + 1 WHERE id = $1`;

export interface AddCompletedJobArgs {
    id: string;
}

export async function addCompletedJob(client: Client, args: AddCompletedJobArgs): Promise<void> {
    await client.query({
        text: addCompletedJobQuery,
        values: [args.id],
        rowMode: "array"
    });
}

export const flagQuery = `-- name: Flag :execrows
UPDATE provider.providers SET flagged_for_review = true, flag_reason = $2 WHERE id = $1 AND NOT flagged_for_review`;

export interface FlagArgs {
    id: string;
    flagReason: string;
}

export const addCancellationQuery = `-- name: AddCancellation :exec
INSERT INTO provider.cancellations (booking_id, provider_id, at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`;

export interface AddCancellationArgs {
    bookingId: string;
    providerId: string;
    at: Date;
}

export async function addCancellation(client: Client, args: AddCancellationArgs): Promise<void> {
    await client.query({
        text: addCancellationQuery,
        values: [args.bookingId, args.providerId, args.at],
        rowMode: "array"
    });
}

export const countCancellationsQuery = `-- name: CountCancellations :one
SELECT count(*) FROM provider.cancellations WHERE provider_id = $1 AND at > $2`;

export interface CountCancellationsArgs {
    providerId: string;
    at: Date;
}

export interface CountCancellationsRow {
    count: string;
}

export async function countCancellations(client: Client, args: CountCancellationsArgs): Promise<CountCancellationsRow | null> {
    const result = await client.query({
        text: countCancellationsQuery,
        values: [args.providerId, args.at],
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

export const deleteProviderQuery = `-- name: DeleteProvider :exec
DELETE FROM provider.providers WHERE id = $1`;

export interface DeleteProviderArgs {
    id: string;
}

export async function deleteProvider(client: Client, args: DeleteProviderArgs): Promise<void> {
    await client.query({
        text: deleteProviderQuery,
        values: [args.id],
        rowMode: "array"
    });
}

export const searchProvidersQuery = `-- name: SearchProviders :many
SELECT p.id, p.full_name, p.phone,
    (CASE WHEN p.account_status = 'active' AND p.level = 0 THEN 'pending' ELSE p.account_status END)::text AS status,
    p.level, p.rating_avg, p.rating_count, p.completed_jobs, p.flagged_for_review, p.flag_reason, p.created_at,
    COALESCE(array_agg(s.service_id ORDER BY s.service_id) FILTER (WHERE s.service_id IS NOT NULL), '{}')::uuid[] AS service_ids
FROM provider.providers p
LEFT JOIN provider.provider_services s ON s.provider_id = p.id
WHERE ($1::uuid IS NULL OR p.id = $1::uuid)
  AND ($2::text = '' OR lower(p.full_name) LIKE $2::text OR p.phone LIKE $2::text)
  AND ($3::text IS NULL
       OR (CASE WHEN p.account_status = 'active' AND p.level = 0 THEN 'pending' ELSE p.account_status END) = $3::text)
  AND ($4::int IS NULL OR p.level = $4::int)
  AND ($5::bool IS NULL OR p.flagged_for_review = $5::bool)
  AND ($6::timestamptz IS NULL OR (p.created_at, p.id) < ($6::timestamptz, $7::uuid))
GROUP BY p.id
ORDER BY p.created_at DESC, p.id DESC
LIMIT $8`;

export interface SearchProvidersArgs {
    id: string | null;
    pattern: string;
    status: string | null;
    level: number | null;
    flagged: boolean | null;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface SearchProvidersRow {
    id: string;
    fullName: string;
    phone: string;
    status: string;
    level: number;
    ratingAvg: number;
    ratingCount: number;
    completedJobs: number;
    flaggedForReview: boolean;
    flagReason: string;
    createdAt: Date;
    serviceIds: string[];
}

export async function searchProviders(client: Client, args: SearchProvidersArgs): Promise<SearchProvidersRow[]> {
    const result = await client.query({
        text: searchProvidersQuery,
        values: [args.id, args.pattern, args.status, args.level, args.flagged, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            fullName: row[1],
            phone: row[2],
            status: row[3],
            level: row[4],
            ratingAvg: row[5],
            ratingCount: row[6],
            completedJobs: row[7],
            flaggedForReview: row[8],
            flagReason: row[9],
            createdAt: row[10],
            serviceIds: row[11]
        };
    });
}

