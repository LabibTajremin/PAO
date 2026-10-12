import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const addReviewableQuery = `-- name: AddReviewable :exec
INSERT INTO rating.reviewable_bookings (booking_id, customer_id, provider_id, customer_name, provider_name, service_name_en,
    service_name_bn, completed_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT DO NOTHING`;

export interface AddReviewableArgs {
    bookingId: string;
    customerId: string;
    providerId: string;
    customerName: string;
    providerName: string;
    serviceNameEn: string;
    serviceNameBn: string;
    completedAt: Date;
}

export async function addReviewable(client: Client, args: AddReviewableArgs): Promise<void> {
    await client.query({
        text: addReviewableQuery,
        values: [args.bookingId, args.customerId, args.providerId, args.customerName, args.providerName, args.serviceNameEn, args.serviceNameBn, args.completedAt],
        rowMode: "array"
    });
}

export const reviewableByIDQuery = `-- name: ReviewableByID :one
SELECT booking_id, customer_id, provider_id, customer_name, provider_name, service_name_en, service_name_bn, completed_at
FROM rating.reviewable_bookings WHERE booking_id = $1`;

export interface ReviewableByIDArgs {
    bookingId: string;
}

export interface ReviewableByIDRow {
    bookingId: string;
    customerId: string;
    providerId: string;
    customerName: string;
    providerName: string;
    serviceNameEn: string;
    serviceNameBn: string;
    completedAt: Date;
}

export async function reviewableByID(client: Client, args: ReviewableByIDArgs): Promise<ReviewableByIDRow | null> {
    const result = await client.query({
        text: reviewableByIDQuery,
        values: [args.bookingId],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        bookingId: row[0],
        customerId: row[1],
        providerId: row[2],
        customerName: row[3],
        providerName: row[4],
        serviceNameEn: row[5],
        serviceNameBn: row[6],
        completedAt: row[7]
    };
}

export const insertReviewQuery = `-- name: InsertReview :exec
INSERT INTO rating.reviews (id, booking_id, author_id, author_role, author_name, subject_id, stars, tags, comment,
    service_name_en, service_name_bn, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`;

export interface InsertReviewArgs {
    id: string;
    bookingId: string;
    authorId: string;
    authorRole: string;
    authorName: string;
    subjectId: string;
    stars: number;
    tags: string[];
    comment: string;
    serviceNameEn: string;
    serviceNameBn: string;
    createdAt: Date;
}

export async function insertReview(client: Client, args: InsertReviewArgs): Promise<void> {
    await client.query({
        text: insertReviewQuery,
        values: [args.id, args.bookingId, args.authorId, args.authorRole, args.authorName, args.subjectId, args.stars, args.tags, args.comment, args.serviceNameEn, args.serviceNameBn, args.createdAt],
        rowMode: "array"
    });
}

export const addToAggregateQuery = `-- name: AddToAggregate :one
INSERT INTO rating.aggregates (subject_id, subject_role, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5)
VALUES ($1, $2, 1, $3::int,
    ($3::int = 1)::int, ($3::int = 2)::int, ($3::int = 3)::int, ($3::int = 4)::int, ($3::int = 5)::int)
ON CONFLICT (subject_id, subject_role) DO UPDATE SET review_count = rating.aggregates.review_count + 1,
    star_sum = rating.aggregates.star_sum + excluded.star_sum, stars_1 = rating.aggregates.stars_1 + excluded.stars_1,
    stars_2 = rating.aggregates.stars_2 + excluded.stars_2, stars_3 = rating.aggregates.stars_3 + excluded.stars_3,
    stars_4 = rating.aggregates.stars_4 + excluded.stars_4, stars_5 = rating.aggregates.stars_5 + excluded.stars_5
RETURNING subject_id, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5`;

export interface AddToAggregateArgs {
    subjectId: string;
    subjectRole: string;
    stars: number;
}

export interface AddToAggregateRow {
    subjectId: string;
    reviewCount: number;
    starSum: string;
    stars_1: number;
    stars_2: number;
    stars_3: number;
    stars_4: number;
    stars_5: number;
}

export async function addToAggregate(client: Client, args: AddToAggregateArgs): Promise<AddToAggregateRow | null> {
    const result = await client.query({
        text: addToAggregateQuery,
        values: [args.subjectId, args.subjectRole, args.stars],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        subjectId: row[0],
        reviewCount: row[1],
        starSum: row[2],
        stars_1: row[3],
        stars_2: row[4],
        stars_3: row[5],
        stars_4: row[6],
        stars_5: row[7]
    };
}

export const aggregatesQuery = `-- name: Aggregates :many
SELECT subject_id, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5
FROM rating.aggregates WHERE subject_role = $1 AND subject_id = ANY($2::uuid[])`;

export interface AggregatesArgs {
    subjectRole: string;
    ids: string[];
}

export interface AggregatesRow {
    subjectId: string;
    reviewCount: number;
    starSum: string;
    stars_1: number;
    stars_2: number;
    stars_3: number;
    stars_4: number;
    stars_5: number;
}

export async function aggregates(client: Client, args: AggregatesArgs): Promise<AggregatesRow[]> {
    const result = await client.query({
        text: aggregatesQuery,
        values: [args.subjectRole, args.ids],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            subjectId: row[0],
            reviewCount: row[1],
            starSum: row[2],
            stars_1: row[3],
            stars_2: row[4],
            stars_3: row[5],
            stars_4: row[6],
            stars_5: row[7]
        };
    });
}

export const hasReviewedQuery = `-- name: HasReviewed :one
SELECT EXISTS (SELECT 1 FROM rating.reviews WHERE booking_id = $1 AND author_id = $2)`;

export interface HasReviewedArgs {
    bookingId: string;
    authorId: string;
}

export interface HasReviewedRow {
    exists: boolean;
}

export async function hasReviewed(client: Client, args: HasReviewedArgs): Promise<HasReviewedRow | null> {
    const result = await client.query({
        text: hasReviewedQuery,
        values: [args.bookingId, args.authorId],
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

export const reviewsQuery = `-- name: Reviews :many
SELECT id, booking_id, author_id, author_role, author_name, subject_id, stars, tags, comment, service_name_en, service_name_bn, created_at
FROM rating.reviews
WHERE subject_id = $1 AND author_role = $2
  AND ($3::timestamptz IS NULL OR (created_at, id) < ($3, $4::uuid))
ORDER BY created_at DESC, id DESC LIMIT $5`;

export interface ReviewsArgs {
    subjectId: string;
    authorRole: string;
    beforeAt: Date | null;
    beforeId: string;
    maxRows: string;
}

export interface ReviewsRow {
    id: string;
    bookingId: string;
    authorId: string;
    authorRole: string;
    authorName: string;
    subjectId: string;
    stars: number;
    tags: string[];
    comment: string;
    serviceNameEn: string;
    serviceNameBn: string;
    createdAt: Date;
}

export async function reviews(client: Client, args: ReviewsArgs): Promise<ReviewsRow[]> {
    const result = await client.query({
        text: reviewsQuery,
        values: [args.subjectId, args.authorRole, args.beforeAt, args.beforeId, args.maxRows],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            bookingId: row[1],
            authorId: row[2],
            authorRole: row[3],
            authorName: row[4],
            subjectId: row[5],
            stars: row[6],
            tags: row[7],
            comment: row[8],
            serviceNameEn: row[9],
            serviceNameBn: row[10],
            createdAt: row[11]
        };
    });
}

