-- +goose Up
-- Admin: platform settings, complaints and the dashboard read model.
CREATE SCHEMA admin;

CREATE TABLE admin.settings (
    key         text PRIMARY KEY,
    value       text        NOT NULL,
    type        text        NOT NULL CHECK (type IN ('integer', 'number', 'boolean', 'string', 'geojson')),
    description text        NOT NULL,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    updated_by  uuid
);

INSERT INTO admin.settings (key, value, type, description) VALUES
    ('booking.accept_timeout_asap_seconds', '180', 'integer', 'Seconds a provider has to answer an ASAP request (D12).'),
    ('booking.accept_timeout_scheduled_seconds', '1800', 'integer', 'Seconds a provider has to answer a scheduled request (D12).'),
    ('booking.start_code_max_attempts', '5', 'integer', 'Wrong start codes allowed before a lockout.'),
    ('booking.start_code_lockout_seconds', '600', 'integer', 'Lockout after too many wrong start codes.'),
    ('search.default_radius_m', '5000', 'integer', 'Search radius for services without their own (D5).'),
    ('quality.rating_floor', '3.5', 'number', 'Average rating below which a provider is flagged (D13).'),
    ('quality.rating_min_jobs', '10', 'integer', 'Jobs before the rating floor applies (D13).'),
    ('quality.max_provider_cancellations_30d', '3', 'integer', 'Provider cancellations in 30 days before a flag (D13).'),
    ('verification.police_clearance_validity_days', '365', 'integer', 'Days a police clearance stays valid from its issue date (PRD §6.4).'),
    ('verification.level2_cooling_off_days', '14', 'integer', 'Days before a failed Level 2 provider may retry (PRD §6.3).'),
    ('documents.retention_days', '365', 'integer', 'Days documents are kept after account closure (D14).'),
    ('service_area.geojson', '', 'geojson', 'Launch area polygon (D5); empty means every location is covered.');

CREATE SEQUENCE admin.ticket_number_seq START 1001;

CREATE TABLE admin.complaints (
    id              uuid PRIMARY KEY,
    ticket_number   bigint      NOT NULL UNIQUE DEFAULT nextval('admin.ticket_number_seq'),
    booking_id      uuid        NOT NULL,
    reporter_id     uuid        NOT NULL,
    reporter_role   text        NOT NULL CHECK (reporter_role IN ('customer', 'provider')),
    against_id      uuid        NOT NULL,
    reason          text        NOT NULL,
    description     text        NOT NULL,
    photo_media_ids uuid[]      NOT NULL DEFAULT '{}',
    status          text        NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'assigned', 'resolved')),
    assignee_id     uuid,
    resolution      text        NOT NULL DEFAULT '',
    verified        boolean     NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    resolved_at     timestamptz
);
CREATE INDEX complaints_queue_idx ON admin.complaints (status, created_at DESC, id DESC);
CREATE INDEX complaints_against_idx ON admin.complaints (against_id) WHERE verified;
CREATE INDEX complaints_reporter_idx ON admin.complaints (reporter_id);

CREATE TABLE admin.complaint_comments (
    id           uuid PRIMARY KEY,
    complaint_id uuid        NOT NULL REFERENCES admin.complaints (id) ON DELETE CASCADE,
    author_id    uuid        NOT NULL,
    body         text        NOT NULL,
    at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX complaint_comments_idx ON admin.complaint_comments (complaint_id, at);

-- Dashboard read model, fed by booking, verification and identity events (A-09).
CREATE TABLE admin.stats_bookings_daily (
    day       date PRIMARY KEY,
    requested int NOT NULL DEFAULT 0,
    completed int NOT NULL DEFAULT 0
);

CREATE TABLE admin.stats_providers (
    provider_id uuid PRIMARY KEY,
    status      text NOT NULL DEFAULT 'pending',
    level       int  NOT NULL DEFAULT 0
);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE admin.outbox (
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
CREATE INDEX outbox_pending_idx ON admin.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE admin.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA admin CASCADE;
