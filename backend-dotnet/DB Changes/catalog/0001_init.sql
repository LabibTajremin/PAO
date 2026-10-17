-- +goose Up
-- Catalog: Category → Service → Sub-service with immutable price versions (PRD §4).
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA catalog;

CREATE TABLE catalog.categories (
    id         uuid PRIMARY KEY,
    name_en    text        NOT NULL,
    name_bn    text        NOT NULL,
    icon_key   text        NOT NULL,
    sort_order int         NOT NULL DEFAULT 0,
    published  boolean     NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE catalog.services (
    id                   uuid PRIMARY KEY,
    category_id          uuid        NOT NULL REFERENCES catalog.categories (id),
    name_en              text        NOT NULL,
    name_bn              text        NOT NULL,
    icon_key             text        NOT NULL,
    service_model        text        NOT NULL CHECK (service_model IN ('on_demand', 'duration_hire', 'listing', 'partner_referral')),
    required_level       int         NOT NULL DEFAULT 1 CHECK (required_level BETWEEN 0 AND 2),
    search_radius_m      int         NOT NULL DEFAULT 5000 CHECK (search_radius_m BETWEEN 500 AND 50000),
    women_providers_only boolean     NOT NULL DEFAULT false,
    requires_level_2     boolean     NOT NULL DEFAULT false,
    level2_checklist     jsonb       NOT NULL DEFAULT '[]',
    sort_order           int         NOT NULL DEFAULT 0,
    published            boolean     NOT NULL DEFAULT false,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX services_category_idx ON catalog.services (category_id);

CREATE TABLE catalog.sub_services (
    id                       uuid PRIMARY KEY,
    service_id               uuid        NOT NULL REFERENCES catalog.services (id),
    name_en                  text        NOT NULL,
    name_bn                  text        NOT NULL,
    description              jsonb       NOT NULL DEFAULT '{"en": "", "bn": ""}',
    inclusions               jsonb       NOT NULL DEFAULT '[]',
    exclusions               jsonb       NOT NULL DEFAULT '[]',
    unit                     text        NOT NULL CHECK (unit IN ('job', 'unit', 'hour', 'day')),
    max_quantity             int         NOT NULL DEFAULT 10 CHECK (max_quantity >= 1),
    sort_order               int         NOT NULL DEFAULT 0,
    published                boolean     NOT NULL DEFAULT false,
    current_price_version_id uuid,
    created_at               timestamptz NOT NULL DEFAULT now(),
    updated_at               timestamptz NOT NULL DEFAULT now(),
    search_text              text GENERATED ALWAYS AS (lower(name_en || ' ' || name_bn)) STORED
);
CREATE INDEX sub_services_service_idx ON catalog.sub_services (service_id);
CREATE INDEX sub_services_search_trgm ON catalog.sub_services USING gin (search_text gin_trgm_ops);

-- Every price change inserts a row; rows are never updated so booked prices stay
-- reproducible (PRD §4).
CREATE TABLE catalog.price_versions (
    id             uuid PRIMARY KEY,
    sub_service_id uuid        NOT NULL REFERENCES catalog.sub_services (id),
    amount_paisa   bigint      NOT NULL CHECK (amount_paisa >= 0),
    effective_from timestamptz NOT NULL DEFAULT now(),
    created_by     uuid        NOT NULL
);
CREATE INDEX price_versions_sub_service_idx ON catalog.price_versions (sub_service_id, effective_from DESC);

ALTER TABLE catalog.sub_services
    ADD CONSTRAINT sub_services_current_price_fk FOREIGN KEY (current_price_version_id) REFERENCES catalog.price_versions (id);

-- +goose StatementBegin
CREATE FUNCTION catalog.reject_price_change() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'price versions are immutable';
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd
CREATE TRIGGER price_versions_immutable BEFORE UPDATE OR DELETE ON catalog.price_versions
    FOR EACH ROW EXECUTE FUNCTION catalog.reject_price_change();

CREATE TABLE catalog.catalog_version (
    singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
    version   bigint  NOT NULL DEFAULT 1
);
INSERT INTO catalog.catalog_version DEFAULT VALUES;

CREATE INDEX services_search_trgm ON catalog.services USING gin (lower(name_en || ' ' || name_bn) gin_trgm_ops);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE catalog.outbox (
    id           uuid PRIMARY KEY,
    aggregate_id text        NOT NULL,
    event_name   text        NOT NULL,
    payload      jsonb       NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    published_at timestamptz,
    attempts     int         NOT NULL DEFAULT 0,
    next_attempt_at timestamptz NOT NULL DEFAULT now(),
    last_error   text,
    dead         boolean     NOT NULL DEFAULT false
);
CREATE INDEX outbox_pending_idx ON catalog.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE catalog.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA catalog CASCADE;
