-- +goose Up
-- Booking: lifecycle, snapshots, items, extras and the timeline (PRD §5).
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA booking;

CREATE SEQUENCE booking.booking_number_seq START 100001;

CREATE TABLE booking.bookings (
    id                      uuid PRIMARY KEY,
    number                  bigint      NOT NULL UNIQUE DEFAULT nextval('booking.booking_number_seq'),
    customer_id             uuid        NOT NULL,
    provider_id             uuid        NOT NULL,
    service_id              uuid        NOT NULL,
    -- Snapshots copied at creation (PRD §9.3 rule 4).
    service_name_en         text        NOT NULL,
    service_name_bn         text        NOT NULL,
    service_model           text        NOT NULL,
    customer_name           text        NOT NULL,
    customer_phone          text        NOT NULL,
    provider_name           text        NOT NULL,
    provider_phone          text        NOT NULL,
    address_id              uuid        NOT NULL,
    address_area            text        NOT NULL,
    address_line1           text        NOT NULL,
    address_line2           text        NOT NULL DEFAULT '',
    address_location        geography(Point, 4326) NOT NULL,
    note                    text        NOT NULL DEFAULT '',
    status                  text        NOT NULL CHECK (status IN ('requested', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'rejected', 'timed_out', 'cancelled')),
    timing                  text        NOT NULL CHECK (timing IN ('asap', 'scheduled')),
    scheduled_at            timestamptz,
    ends_at                 timestamptz,
    accept_deadline         timestamptz NOT NULL,
    total_paisa             bigint      NOT NULL CHECK (total_paisa >= 0),
    start_code              text        NOT NULL,
    start_code_attempts     int         NOT NULL DEFAULT 0,
    start_code_locked_until timestamptz,
    cash_received           boolean     NOT NULL DEFAULT false,
    idempotency_key         text        NOT NULL,
    cancel_reason           text        NOT NULL DEFAULT '',
    cancelled_by            text,
    reject_reason           text        NOT NULL DEFAULT '',
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),
    accepted_at             timestamptz,
    started_at              timestamptz,
    completed_at            timestamptz,
    cancelled_at            timestamptz,
    UNIQUE (customer_id, idempotency_key)
);
CREATE INDEX bookings_customer_idx ON booking.bookings (customer_id, created_at DESC, id DESC);
CREATE INDEX bookings_provider_idx ON booking.bookings (provider_id, created_at DESC, id DESC);
CREATE INDEX bookings_status_idx ON booking.bookings (status, created_at DESC);
CREATE INDEX bookings_active_job_idx ON booking.bookings (provider_id) WHERE status IN ('accepted', 'on_the_way', 'arrived', 'in_progress');
-- A customer may not hold two open requests to the same provider (P07 task 2).
CREATE UNIQUE INDEX bookings_one_request_per_pair ON booking.bookings (customer_id, provider_id) WHERE status = 'requested';

CREATE TABLE booking.extras_proposals (
    id           uuid PRIMARY KEY,
    booking_id   uuid        NOT NULL REFERENCES booking.bookings (id) ON DELETE CASCADE,
    status       text        NOT NULL CHECK (status IN ('pending', 'approved', 'declined')),
    added_paisa  bigint      NOT NULL,
    proposed_at  timestamptz NOT NULL DEFAULT now(),
    decided_at   timestamptz
);
CREATE UNIQUE INDEX extras_one_pending ON booking.extras_proposals (booking_id) WHERE status = 'pending';

CREATE TABLE booking.booking_items (
    id               uuid PRIMARY KEY,
    booking_id       uuid        NOT NULL REFERENCES booking.bookings (id) ON DELETE CASCADE,
    proposal_id      uuid REFERENCES booking.extras_proposals (id),
    sub_service_id   uuid        NOT NULL,
    price_version_id uuid        NOT NULL,
    name_en          text        NOT NULL,
    name_bn          text        NOT NULL,
    unit             text        NOT NULL,
    quantity         int         NOT NULL CHECK (quantity >= 1),
    unit_price_paisa bigint      NOT NULL,
    total_paisa      bigint      NOT NULL,
    extra            boolean     NOT NULL DEFAULT false,
    position         int         NOT NULL
);
CREATE INDEX booking_items_booking_idx ON booking.booking_items (booking_id, position);

CREATE TABLE booking.timeline (
    id         uuid PRIMARY KEY,
    booking_id uuid        NOT NULL REFERENCES booking.bookings (id) ON DELETE CASCADE,
    status     text        NOT NULL,
    actor      text        NOT NULL CHECK (actor IN ('customer', 'provider', 'system', 'admin')),
    reason     text        NOT NULL DEFAULT '',
    at         timestamptz NOT NULL
);
CREATE INDEX timeline_booking_idx ON booking.timeline (booking_id, at);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE booking.outbox (
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
CREATE INDEX outbox_pending_idx ON booking.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE booking.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA booking CASCADE;
