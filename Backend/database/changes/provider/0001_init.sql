-- +goose Up
-- Provider: enrolment profile, services offered and read-model copies used for search.
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA provider;

CREATE TABLE provider.providers (
    id                     uuid PRIMARY KEY,
    phone                  text        NOT NULL DEFAULT '',
    full_name              text        NOT NULL DEFAULT '',
    date_of_birth          date,
    gender                 text CHECK (gender IN ('female', 'male', 'other')),
    present_address        text        NOT NULL DEFAULT '',
    permanent_address      text        NOT NULL DEFAULT '',
    bio                    text        NOT NULL DEFAULT '',
    photo_media_id         uuid,
    experience_years       int         NOT NULL DEFAULT 0,
    language               text        NOT NULL DEFAULT 'bn' CHECK (language IN ('en', 'bn')),
    home_base              geography(Point, 4326),
    working_radius_m       int         NOT NULL DEFAULT 0,
    emergency_name         text        NOT NULL DEFAULT '',
    emergency_relation     text        NOT NULL DEFAULT '',
    emergency_phone        text        NOT NULL DEFAULT '',
    emergency_verified_at  timestamptz,
    coc_version            text        NOT NULL DEFAULT '',
    coc_accepted_at        timestamptz,
    steps_done             text[]      NOT NULL DEFAULT '{}',
    submitted_at           timestamptz,
    -- Copies kept current from other modules' events (PRD §9.3 rule 4).
    account_status         text        NOT NULL DEFAULT 'active',
    level                  int         NOT NULL DEFAULT 0,
    can_receive_bookings   boolean     NOT NULL DEFAULT false,
    rating_avg             double precision NOT NULL DEFAULT 0,
    rating_count           int         NOT NULL DEFAULT 0,
    completed_jobs         int         NOT NULL DEFAULT 0,
    flagged_for_review     boolean     NOT NULL DEFAULT false,
    flag_reason            text        NOT NULL DEFAULT '',
    created_at             timestamptz NOT NULL DEFAULT now(),
    updated_at             timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX providers_home_base_gist ON provider.providers USING gist (home_base);
CREATE INDEX providers_name_idx ON provider.providers (lower(full_name));

CREATE TABLE provider.provider_services (
    provider_id uuid NOT NULL REFERENCES provider.providers (id) ON DELETE CASCADE,
    service_id  uuid NOT NULL,
    PRIMARY KEY (provider_id, service_id)
);
CREATE INDEX provider_services_service_idx ON provider.provider_services (service_id);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE provider.outbox (
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
CREATE INDEX outbox_pending_idx ON provider.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE provider.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA provider CASCADE;
