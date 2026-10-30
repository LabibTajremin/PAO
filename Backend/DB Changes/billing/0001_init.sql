-- +goose Up
-- Billing: the merchant ledger and payment submissions (ADR-0035).
CREATE SCHEMA billing;

-- A commission is a debit, a confirmed payment a credit. Amounts are positive; the kind
-- gives the sign. One commission per booking makes a redelivered completion harmless.
CREATE TABLE billing.ledger_entries (
    id             uuid PRIMARY KEY,
    provider_id    uuid        NOT NULL,
    kind           text        NOT NULL CHECK (kind IN ('commission', 'payment')),
    amount_paisa   bigint      NOT NULL CHECK (amount_paisa >= 0),
    booking_id     uuid,
    booking_number bigint,
    job_total_paisa bigint,
    rate_bp        int,
    submission_id  uuid UNIQUE,
    created_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ledger_entries_booking_kind_key UNIQUE (booking_id, kind),
    CHECK ((kind = 'commission') = (booking_id IS NOT NULL)),
    CHECK ((kind = 'payment') = (submission_id IS NOT NULL))
);
CREATE INDEX ledger_entries_provider_idx ON billing.ledger_entries (provider_id, created_at DESC, id DESC);

CREATE TABLE billing.payment_submissions (
    id           uuid PRIMARY KEY,
    provider_id  uuid        NOT NULL,
    amount_paisa bigint      NOT NULL CHECK (amount_paisa > 0),
    method       text        NOT NULL CHECK (method IN ('cash_to_agent', 'bkash', 'nagad', 'bank')),
    reference    text        NOT NULL,
    status       text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
    reviewer_id  uuid,
    reason       text        NOT NULL DEFAULT '',
    created_at   timestamptz NOT NULL DEFAULT now(),
    reviewed_at  timestamptz,
    CHECK ((status = 'pending') = (reviewed_at IS NULL)),
    CHECK (status <> 'rejected' OR length(reason) > 0)
);
CREATE INDEX payment_submissions_queue_idx ON billing.payment_submissions (status, created_at DESC, id DESC);
CREATE INDEX payment_submissions_provider_idx ON billing.payment_submissions (provider_id, created_at DESC, id DESC);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE billing.outbox (
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
CREATE INDEX outbox_pending_idx ON billing.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE billing.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA billing CASCADE;
