-- +goose Up
-- Verification: items, documents, levels, Level 2 sessions and the NID block list.
CREATE SCHEMA verification;

CREATE TABLE verification.items (
    provider_id      uuid        NOT NULL,
    item_type        text        NOT NULL CHECK (item_type IN ('nid', 'selfie', 'police_clearance', 'address', 'emergency_contact', 'skill_proof', 'service_area', 'code_of_conduct')),
    status           text        NOT NULL CHECK (status IN ('missing', 'pending', 'approved', 'rejected', 'expired')),
    rejection_reason text        NOT NULL DEFAULT '',
    fields           jsonb       NOT NULL DEFAULT '{}',
    submitted_at     timestamptz,
    decided_at       timestamptz,
    decided_by       uuid,
    expires_at       timestamptz,
    PRIMARY KEY (provider_id, item_type)
);
CREATE INDEX items_pending_idx ON verification.items (submitted_at) WHERE status = 'pending';
CREATE INDEX items_expiry_idx ON verification.items (expires_at) WHERE status = 'approved' AND expires_at IS NOT NULL;

CREATE TABLE verification.documents (
    id          uuid PRIMARY KEY,
    provider_id uuid        NOT NULL,
    item_type   text        NOT NULL,
    kind        text        NOT NULL,
    media_id    uuid        NOT NULL,
    current     boolean     NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX documents_provider_idx ON verification.documents (provider_id, item_type) WHERE current;

-- NID numbers are encrypted (AES-256-GCM); the keyed hash finds blocked identities
-- without decrypting (PRD §6.4, §6.6).
CREATE TABLE verification.nid_records (
    provider_id    uuid PRIMARY KEY,
    nid_ciphertext bytea       NOT NULL,
    nid_hash       text        NOT NULL,
    updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX nid_records_hash_idx ON verification.nid_records (nid_hash);

CREATE TABLE verification.blocked_nids (
    nid_hash   text PRIMARY KEY,
    reason     text        NOT NULL,
    blocked_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE verification.levels (
    provider_id      uuid PRIMARY KEY,
    level            int         NOT NULL DEFAULT 0 CHECK (level BETWEEN 0 AND 2),
    level2_passed_at timestamptz,
    blocked          boolean     NOT NULL DEFAULT false,
    service_ids      uuid[]      NOT NULL DEFAULT '{}',
    submitted_at     timestamptz,
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE verification.level2_sessions (
    id             uuid PRIMARY KEY,
    provider_id    uuid        NOT NULL,
    service_id     uuid        NOT NULL,
    scheduled_at   timestamptz NOT NULL,
    location       text        NOT NULL,
    status         text        NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    result         text CHECK (result IN ('pass', 'fail', 'retest')),
    checklist      jsonb       NOT NULL DEFAULT '[]',
    notes          text        NOT NULL DEFAULT '',
    visit_lat      double precision,
    visit_lng      double precision,
    photo_media_ids uuid[]     NOT NULL DEFAULT '{}',
    decided_by     uuid,
    decided_at     timestamptz,
    created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX level2_sessions_provider_idx ON verification.level2_sessions (provider_id, created_at DESC);

CREATE TABLE verification.reminders_sent (
    provider_id uuid        NOT NULL,
    item_type   text        NOT NULL,
    expires_at  timestamptz NOT NULL,
    days_before int         NOT NULL,
    sent_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (provider_id, item_type, expires_at, days_before)
);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE verification.outbox (
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
CREATE INDEX outbox_pending_idx ON verification.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE verification.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA verification CASCADE;
