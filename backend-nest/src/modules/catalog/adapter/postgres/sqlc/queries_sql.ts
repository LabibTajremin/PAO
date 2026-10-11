import { QueryArrayConfig, QueryArrayResult } from "pg";

interface Client {
    query: (config: QueryArrayConfig) => Promise<QueryArrayResult>;
}

export const categoriesQuery = `-- name: Categories :many
SELECT id, name_en, name_bn, icon_key, sort_order, published FROM catalog.categories ORDER BY sort_order, name_en`;

export interface CategoriesRow {
    id: string;
    nameEn: string;
    nameBn: string;
    iconKey: string;
    sortOrder: number;
    published: boolean;
}

export async function categories(client: Client): Promise<CategoriesRow[]> {
    const result = await client.query({
        text: categoriesQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            nameEn: row[1],
            nameBn: row[2],
            iconKey: row[3],
            sortOrder: row[4],
            published: row[5]
        };
    });
}

export const servicesQuery = `-- name: Services :many
SELECT id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
       women_providers_only, requires_level_2, level2_checklist, sort_order, published
FROM catalog.services ORDER BY sort_order, name_en`;

export interface ServicesRow {
    id: string;
    categoryId: string;
    nameEn: string;
    nameBn: string;
    iconKey: string;
    serviceModel: string;
    requiredLevel: number;
    searchRadiusM: number;
    womenProvidersOnly: boolean;
    requiresLevel_2: boolean;
    level2Checklist: any;
    sortOrder: number;
    published: boolean;
}

export async function services(client: Client): Promise<ServicesRow[]> {
    const result = await client.query({
        text: servicesQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            categoryId: row[1],
            nameEn: row[2],
            nameBn: row[3],
            iconKey: row[4],
            serviceModel: row[5],
            requiredLevel: row[6],
            searchRadiusM: row[7],
            womenProvidersOnly: row[8],
            requiresLevel_2: row[9],
            level2Checklist: row[10],
            sortOrder: row[11],
            published: row[12]
        };
    });
}

export const subServicesQuery = `-- name: SubServices :many
SELECT s.id, s.service_id, s.name_en, s.name_bn, s.description, s.inclusions, s.exclusions, s.unit,
       s.max_quantity, s.sort_order, s.published, p.id AS price_version_id, p.amount_paisa
FROM catalog.sub_services s JOIN catalog.price_versions p ON p.id = s.current_price_version_id
ORDER BY s.sort_order, s.name_en`;

export interface SubServicesRow {
    id: string;
    serviceId: string;
    nameEn: string;
    nameBn: string;
    description: any;
    inclusions: any;
    exclusions: any;
    unit: string;
    maxQuantity: number;
    sortOrder: number;
    published: boolean;
    priceVersionId: string;
    amountPaisa: string;
}

export async function subServices(client: Client): Promise<SubServicesRow[]> {
    const result = await client.query({
        text: subServicesQuery,
        values: [],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            serviceId: row[1],
            nameEn: row[2],
            nameBn: row[3],
            description: row[4],
            inclusions: row[5],
            exclusions: row[6],
            unit: row[7],
            maxQuantity: row[8],
            sortOrder: row[9],
            published: row[10],
            priceVersionId: row[11],
            amountPaisa: row[12]
        };
    });
}

export const serviceByIDQuery = `-- name: ServiceByID :one
SELECT id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
       women_providers_only, requires_level_2, level2_checklist, sort_order, published
FROM catalog.services WHERE id = $1`;

export interface ServiceByIDArgs {
    id: string;
}

export interface ServiceByIDRow {
    id: string;
    categoryId: string;
    nameEn: string;
    nameBn: string;
    iconKey: string;
    serviceModel: string;
    requiredLevel: number;
    searchRadiusM: number;
    womenProvidersOnly: boolean;
    requiresLevel_2: boolean;
    level2Checklist: any;
    sortOrder: number;
    published: boolean;
}

export async function serviceByID(client: Client, args: ServiceByIDArgs): Promise<ServiceByIDRow | null> {
    const result = await client.query({
        text: serviceByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        categoryId: row[1],
        nameEn: row[2],
        nameBn: row[3],
        iconKey: row[4],
        serviceModel: row[5],
        requiredLevel: row[6],
        searchRadiusM: row[7],
        womenProvidersOnly: row[8],
        requiresLevel_2: row[9],
        level2Checklist: row[10],
        sortOrder: row[11],
        published: row[12]
    };
}

export const subServicesOfServiceQuery = `-- name: SubServicesOfService :many
SELECT s.id, s.service_id, s.name_en, s.name_bn, s.description, s.inclusions, s.exclusions, s.unit,
       s.max_quantity, s.sort_order, s.published, p.id AS price_version_id, p.amount_paisa
FROM catalog.sub_services s JOIN catalog.price_versions p ON p.id = s.current_price_version_id
WHERE s.service_id = $1 ORDER BY s.sort_order, s.name_en`;

export interface SubServicesOfServiceArgs {
    serviceId: string;
}

export interface SubServicesOfServiceRow {
    id: string;
    serviceId: string;
    nameEn: string;
    nameBn: string;
    description: any;
    inclusions: any;
    exclusions: any;
    unit: string;
    maxQuantity: number;
    sortOrder: number;
    published: boolean;
    priceVersionId: string;
    amountPaisa: string;
}

export async function subServicesOfService(client: Client, args: SubServicesOfServiceArgs): Promise<SubServicesOfServiceRow[]> {
    const result = await client.query({
        text: subServicesOfServiceQuery,
        values: [args.serviceId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            serviceId: row[1],
            nameEn: row[2],
            nameBn: row[3],
            description: row[4],
            inclusions: row[5],
            exclusions: row[6],
            unit: row[7],
            maxQuantity: row[8],
            sortOrder: row[9],
            published: row[10],
            priceVersionId: row[11],
            amountPaisa: row[12]
        };
    });
}

export const subServiceByIDQuery = `-- name: SubServiceByID :one
SELECT s.id, s.service_id, s.name_en, s.name_bn, s.description, s.inclusions, s.exclusions, s.unit,
       s.max_quantity, s.sort_order, s.published, p.id AS price_version_id, p.amount_paisa
FROM catalog.sub_services s JOIN catalog.price_versions p ON p.id = s.current_price_version_id
WHERE s.id = $1`;

export interface SubServiceByIDArgs {
    id: string;
}

export interface SubServiceByIDRow {
    id: string;
    serviceId: string;
    nameEn: string;
    nameBn: string;
    description: any;
    inclusions: any;
    exclusions: any;
    unit: string;
    maxQuantity: number;
    sortOrder: number;
    published: boolean;
    priceVersionId: string;
    amountPaisa: string;
}

export async function subServiceByID(client: Client, args: SubServiceByIDArgs): Promise<SubServiceByIDRow | null> {
    const result = await client.query({
        text: subServiceByIDQuery,
        values: [args.id],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        id: row[0],
        serviceId: row[1],
        nameEn: row[2],
        nameBn: row[3],
        description: row[4],
        inclusions: row[5],
        exclusions: row[6],
        unit: row[7],
        maxQuantity: row[8],
        sortOrder: row[9],
        published: row[10],
        priceVersionId: row[11],
        amountPaisa: row[12]
    };
}

export const categoryExistsQuery = `-- name: CategoryExists :one
SELECT EXISTS (SELECT 1 FROM catalog.categories WHERE id = $1)`;

export interface CategoryExistsArgs {
    id: string;
}

export interface CategoryExistsRow {
    exists: boolean;
}

export async function categoryExists(client: Client, args: CategoryExistsArgs): Promise<CategoryExistsRow | null> {
    const result = await client.query({
        text: categoryExistsQuery,
        values: [args.id],
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

export const upsertCategoryQuery = `-- name: UpsertCategory :execrows
INSERT INTO catalog.categories (id, name_en, name_bn, icon_key, sort_order, published, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
ON CONFLICT (id) DO UPDATE SET name_en = excluded.name_en, name_bn = excluded.name_bn, icon_key = excluded.icon_key,
    sort_order = excluded.sort_order, published = excluded.published, updated_at = excluded.updated_at`;

export interface UpsertCategoryArgs {
    id: string;
    nameEn: string;
    nameBn: string;
    iconKey: string;
    sortOrder: number;
    published: boolean;
    createdAt: Date;
}

export const upsertServiceQuery = `-- name: UpsertService :execrows
INSERT INTO catalog.services (id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
    women_providers_only, requires_level_2, level2_checklist, sort_order, published, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $14)
ON CONFLICT (id) DO UPDATE SET category_id = excluded.category_id, name_en = excluded.name_en, name_bn = excluded.name_bn,
    icon_key = excluded.icon_key, service_model = excluded.service_model, required_level = excluded.required_level,
    search_radius_m = excluded.search_radius_m, women_providers_only = excluded.women_providers_only,
    requires_level_2 = excluded.requires_level_2, level2_checklist = excluded.level2_checklist,
    sort_order = excluded.sort_order, published = excluded.published, updated_at = excluded.updated_at`;

export interface UpsertServiceArgs {
    id: string;
    categoryId: string;
    nameEn: string;
    nameBn: string;
    iconKey: string;
    serviceModel: string;
    requiredLevel: number;
    searchRadiusM: number;
    womenProvidersOnly: boolean;
    requiresLevel_2: boolean;
    level2Checklist: any;
    sortOrder: number;
    published: boolean;
    createdAt: Date;
}

export const upsertSubServiceQuery = `-- name: UpsertSubService :execrows
INSERT INTO catalog.sub_services (id, service_id, name_en, name_bn, description, inclusions, exclusions, unit,
    max_quantity, sort_order, published, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $12)
ON CONFLICT (id) DO UPDATE SET service_id = excluded.service_id, name_en = excluded.name_en, name_bn = excluded.name_bn,
    description = excluded.description, inclusions = excluded.inclusions, exclusions = excluded.exclusions,
    unit = excluded.unit, max_quantity = excluded.max_quantity, sort_order = excluded.sort_order,
    published = excluded.published, updated_at = excluded.updated_at`;

export interface UpsertSubServiceArgs {
    id: string;
    serviceId: string;
    nameEn: string;
    nameBn: string;
    description: any;
    inclusions: any;
    exclusions: any;
    unit: string;
    maxQuantity: number;
    sortOrder: number;
    published: boolean;
    createdAt: Date;
}

export const addPriceQuery = `-- name: AddPrice :exec
WITH p AS (
    INSERT INTO catalog.price_versions (id, sub_service_id, amount_paisa, effective_from, created_by)
    VALUES ($1, $2, $3, $4, $5) RETURNING id, sub_service_id
)
UPDATE catalog.sub_services s SET current_price_version_id = p.id FROM p WHERE s.id = p.sub_service_id`;

export interface AddPriceArgs {
    id: string;
    subServiceId: string;
    amountPaisa: string;
    effectiveFrom: Date;
    createdBy: string;
}

export async function addPrice(client: Client, args: AddPriceArgs): Promise<void> {
    await client.query({
        text: addPriceQuery,
        values: [args.id, args.subServiceId, args.amountPaisa, args.effectiveFrom, args.createdBy],
        rowMode: "array"
    });
}

export const priceHistoryQuery = `-- name: PriceHistory :many
SELECT id, sub_service_id, amount_paisa, effective_from, created_by
FROM catalog.price_versions WHERE sub_service_id = $1 ORDER BY effective_from DESC, id DESC`;

export interface PriceHistoryArgs {
    subServiceId: string;
}

export interface PriceHistoryRow {
    id: string;
    subServiceId: string;
    amountPaisa: string;
    effectiveFrom: Date;
    createdBy: string;
}

export async function priceHistory(client: Client, args: PriceHistoryArgs): Promise<PriceHistoryRow[]> {
    const result = await client.query({
        text: priceHistoryQuery,
        values: [args.subServiceId],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0],
            subServiceId: row[1],
            amountPaisa: row[2],
            effectiveFrom: row[3],
            createdBy: row[4]
        };
    });
}

export const bumpVersionQuery = `-- name: BumpVersion :one
UPDATE catalog.catalog_version SET version = version + 1 RETURNING version`;

export interface BumpVersionRow {
    version: string;
}

export async function bumpVersion(client: Client): Promise<BumpVersionRow | null> {
    const result = await client.query({
        text: bumpVersionQuery,
        values: [],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        version: row[0]
    };
}

export const versionQuery = `-- name: Version :one
SELECT version FROM catalog.catalog_version`;

export interface VersionRow {
    version: string;
}

export async function version(client: Client): Promise<VersionRow | null> {
    const result = await client.query({
        text: versionQuery,
        values: [],
        rowMode: "array"
    });
    if (result.rows.length !== 1) {
        return null;
    }
    const row = result.rows[0]!;
    return {
        version: row[0]
    };
}

export const searchServicesQuery = `-- name: SearchServices :many
SELECT id FROM catalog.services
WHERE published AND (lower(name_en || ' ' || name_bn) LIKE '%' || lower($1::text) || '%'
    OR word_similarity(lower($1::text), lower(name_en || ' ' || name_bn)) > 0.5)
ORDER BY word_similarity(lower($1::text), lower(name_en || ' ' || name_bn)) DESC LIMIT 20`;

export interface SearchServicesArgs {
    term: string;
}

export interface SearchServicesRow {
    id: string;
}

export async function searchServices(client: Client, args: SearchServicesArgs): Promise<SearchServicesRow[]> {
    const result = await client.query({
        text: searchServicesQuery,
        values: [args.term],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0]
        };
    });
}

export const searchSubServicesQuery = `-- name: SearchSubServices :many
SELECT id FROM catalog.sub_services
WHERE published AND (search_text LIKE '%' || lower($1::text) || '%'
    OR word_similarity(lower($1::text), search_text) > 0.5)
ORDER BY word_similarity(lower($1::text), search_text) DESC LIMIT 30`;

export interface SearchSubServicesArgs {
    term: string;
}

export interface SearchSubServicesRow {
    id: string;
}

export async function searchSubServices(client: Client, args: SearchSubServicesArgs): Promise<SearchSubServicesRow[]> {
    const result = await client.query({
        text: searchSubServicesQuery,
        values: [args.term],
        rowMode: "array"
    });
    return result.rows.map(row => {
        return {
            id: row[0]
        };
    });
}

