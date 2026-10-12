-- name: Categories :many
SELECT id, name_en, name_bn, icon_key, sort_order, published FROM catalog.categories ORDER BY sort_order, name_en;

-- name: Services :many
SELECT id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
       women_providers_only, requires_level_2, level2_checklist, sort_order, published
FROM catalog.services ORDER BY sort_order, name_en;

-- name: SubServices :many
SELECT s.id, s.service_id, s.name_en, s.name_bn, s.description, s.inclusions, s.exclusions, s.unit,
       s.max_quantity, s.sort_order, s.published, p.id AS price_version_id, p.amount_paisa
FROM catalog.sub_services s JOIN catalog.price_versions p ON p.id = s.current_price_version_id
ORDER BY s.sort_order, s.name_en;

-- name: ServiceByID :one
SELECT id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
       women_providers_only, requires_level_2, level2_checklist, sort_order, published
FROM catalog.services WHERE id = $1;

-- name: SubServicesOfService :many
SELECT s.id, s.service_id, s.name_en, s.name_bn, s.description, s.inclusions, s.exclusions, s.unit,
       s.max_quantity, s.sort_order, s.published, p.id AS price_version_id, p.amount_paisa
FROM catalog.sub_services s JOIN catalog.price_versions p ON p.id = s.current_price_version_id
WHERE s.service_id = $1 ORDER BY s.sort_order, s.name_en;

-- name: SubServiceByID :one
SELECT s.id, s.service_id, s.name_en, s.name_bn, s.description, s.inclusions, s.exclusions, s.unit,
       s.max_quantity, s.sort_order, s.published, p.id AS price_version_id, p.amount_paisa
FROM catalog.sub_services s JOIN catalog.price_versions p ON p.id = s.current_price_version_id
WHERE s.id = $1;

-- name: CategoryExists :one
SELECT EXISTS (SELECT 1 FROM catalog.categories WHERE id = $1);

-- name: UpsertCategory :execrows
INSERT INTO catalog.categories (id, name_en, name_bn, icon_key, sort_order, published, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
ON CONFLICT (id) DO UPDATE SET name_en = excluded.name_en, name_bn = excluded.name_bn, icon_key = excluded.icon_key,
    sort_order = excluded.sort_order, published = excluded.published, updated_at = excluded.updated_at;

-- name: UpsertService :execrows
INSERT INTO catalog.services (id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
    women_providers_only, requires_level_2, level2_checklist, sort_order, published, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $14)
ON CONFLICT (id) DO UPDATE SET category_id = excluded.category_id, name_en = excluded.name_en, name_bn = excluded.name_bn,
    icon_key = excluded.icon_key, service_model = excluded.service_model, required_level = excluded.required_level,
    search_radius_m = excluded.search_radius_m, women_providers_only = excluded.women_providers_only,
    requires_level_2 = excluded.requires_level_2, level2_checklist = excluded.level2_checklist,
    sort_order = excluded.sort_order, published = excluded.published, updated_at = excluded.updated_at;

-- name: UpsertSubService :execrows
INSERT INTO catalog.sub_services (id, service_id, name_en, name_bn, description, inclusions, exclusions, unit,
    max_quantity, sort_order, published, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $12)
ON CONFLICT (id) DO UPDATE SET service_id = excluded.service_id, name_en = excluded.name_en, name_bn = excluded.name_bn,
    description = excluded.description, inclusions = excluded.inclusions, exclusions = excluded.exclusions,
    unit = excluded.unit, max_quantity = excluded.max_quantity, sort_order = excluded.sort_order,
    published = excluded.published, updated_at = excluded.updated_at;

-- name: AddPrice :exec
WITH p AS (
    INSERT INTO catalog.price_versions (id, sub_service_id, amount_paisa, effective_from, created_by)
    VALUES ($1, $2, $3, $4, $5) RETURNING id, sub_service_id
)
UPDATE catalog.sub_services s SET current_price_version_id = p.id FROM p WHERE s.id = p.sub_service_id;

-- name: PriceHistory :many
SELECT id, sub_service_id, amount_paisa, effective_from, created_by
FROM catalog.price_versions WHERE sub_service_id = $1 ORDER BY effective_from DESC, id DESC;

-- name: BumpVersion :one
UPDATE catalog.catalog_version SET version = version + 1 RETURNING version;

-- name: Version :one
SELECT version FROM catalog.catalog_version;

-- name: SearchServices :many
SELECT id FROM catalog.services
WHERE published AND (lower(name_en || ' ' || name_bn) LIKE '%' || lower(sqlc.arg(term)::text) || '%'
    OR word_similarity(lower(sqlc.arg(term)::text), lower(name_en || ' ' || name_bn)) > 0.5)
ORDER BY word_similarity(lower(sqlc.arg(term)::text), lower(name_en || ' ' || name_bn)) DESC LIMIT 20;

-- name: SearchSubServices :many
SELECT id FROM catalog.sub_services
WHERE published AND (search_text LIKE '%' || lower(sqlc.arg(term)::text) || '%'
    OR word_similarity(lower(sqlc.arg(term)::text), search_text) > 0.5)
ORDER BY word_similarity(lower(sqlc.arg(term)::text), search_text) DESC LIMIT 30;
