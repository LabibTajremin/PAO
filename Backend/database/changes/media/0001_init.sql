-- +goose Up
-- Media: metadata for objects uploaded directly to private storage (PRD §6.6).
CREATE SCHEMA media;

CREATE TABLE media.objects (
    id           uuid PRIMARY KEY,
    owner_id     uuid        NOT NULL,
    purpose      text        NOT NULL CHECK (purpose IN ('avatar', 'nid_front', 'nid_back', 'selfie', 'police_clearance', 'skill_proof', 'address_proof', 'complaint_photo', 'level2_photo')),
    content_type text        NOT NULL,
    size_bytes   bigint      NOT NULL CHECK (size_bytes > 0),
    bucket       text        NOT NULL,
    object_key   text        NOT NULL UNIQUE,
    status       text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed')),
    attached     boolean     NOT NULL DEFAULT false,
    created_at   timestamptz NOT NULL DEFAULT now(),
    confirmed_at timestamptz
);
CREATE INDEX objects_owner_idx ON media.objects (owner_id);
CREATE INDEX objects_orphan_idx ON media.objects (created_at) WHERE NOT attached;

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE media.outbox (
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
CREATE INDEX outbox_pending_idx ON media.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE media.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA media CASCADE;
