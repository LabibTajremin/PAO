-- +goose Up
-- Rating: two-way reviews and incrementally updated aggregates (C-11, P-09).
CREATE SCHEMA rating;

-- Completed bookings copied from BookingCompleted events: the only bookings that may
-- be reviewed, once per side.
CREATE TABLE rating.reviewable_bookings (
    booking_id      uuid PRIMARY KEY,
    customer_id     uuid        NOT NULL,
    provider_id     uuid        NOT NULL,
    customer_name   text        NOT NULL,
    provider_name   text        NOT NULL,
    service_name_en text        NOT NULL,
    service_name_bn text        NOT NULL,
    completed_at    timestamptz NOT NULL
);

CREATE TABLE rating.reviews (
    id              uuid PRIMARY KEY,
    booking_id      uuid        NOT NULL,
    author_id       uuid        NOT NULL,
    author_role     text        NOT NULL CHECK (author_role IN ('customer', 'provider')),
    author_name     text        NOT NULL,
    subject_id      uuid        NOT NULL,
    stars           int         NOT NULL CHECK (stars BETWEEN 1 AND 5),
    tags            text[]      NOT NULL DEFAULT '{}',
    comment         text        NOT NULL DEFAULT '' CHECK (length(comment) <= 500),
    service_name_en text        NOT NULL,
    service_name_bn text        NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (booking_id, author_role)
);
CREATE INDEX reviews_subject_idx ON rating.reviews (subject_id, created_at DESC, id DESC);

CREATE TABLE rating.aggregates (
    subject_id   uuid   NOT NULL,
    subject_role text   NOT NULL CHECK (subject_role IN ('customer', 'provider')),
    review_count int    NOT NULL DEFAULT 0,
    star_sum     bigint NOT NULL DEFAULT 0,
    stars_1      int    NOT NULL DEFAULT 0,
    stars_2      int    NOT NULL DEFAULT 0,
    stars_3      int    NOT NULL DEFAULT 0,
    stars_4      int    NOT NULL DEFAULT 0,
    stars_5      int    NOT NULL DEFAULT 0,
    PRIMARY KEY (subject_id, subject_role)
);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE rating.outbox (
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
CREATE INDEX outbox_pending_idx ON rating.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE rating.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA rating CASCADE;
