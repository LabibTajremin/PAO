-- +goose Up
-- Customer: profiles and saved addresses (C-01, C-02).
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA customer;

CREATE TABLE customer.customers (
    id             uuid PRIMARY KEY,
    name           text        NOT NULL,
    photo_media_id uuid,
    language       text        NOT NULL DEFAULT 'bn' CHECK (language IN ('en', 'bn')),
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE customer.addresses (
    id          uuid PRIMARY KEY,
    customer_id uuid                   NOT NULL REFERENCES customer.customers (id) ON DELETE CASCADE,
    label       text                   NOT NULL CHECK (label IN ('home', 'office', 'other')),
    line1       text                   NOT NULL,
    line2       text                   NOT NULL DEFAULT '',
    area        text                   NOT NULL DEFAULT '',
    location    geography(Point, 4326) NOT NULL,
    is_default  boolean                NOT NULL DEFAULT false,
    created_at  timestamptz            NOT NULL DEFAULT now(),
    updated_at  timestamptz            NOT NULL DEFAULT now()
);
CREATE INDEX addresses_customer_idx ON customer.addresses (customer_id);
CREATE INDEX addresses_location_gist ON customer.addresses USING gist (location);
CREATE UNIQUE INDEX addresses_one_default ON customer.addresses (customer_id) WHERE is_default;

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE customer.outbox (
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
CREATE INDEX outbox_pending_idx ON customer.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE customer.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA customer CASCADE;
