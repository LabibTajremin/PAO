-- +goose Up
-- Scheduled delivery (ADR-0041). A subscription stores the pattern; its dates are computed.
-- Only exceptions get a row in subscription_dates: a date skipped or changed by the
-- customer, declined by the merchant, cancelled with the rest, or made into a booking.
CREATE SEQUENCE booking.subscription_number_seq START 500001;

CREATE TABLE booking.subscriptions (
    id               uuid PRIMARY KEY,
    number           bigint      NOT NULL UNIQUE DEFAULT nextval('booking.subscription_number_seq'),
    customer_id      uuid        NOT NULL,
    provider_id      uuid        NOT NULL,
    service_id       uuid        NOT NULL,
    -- Snapshots copied at ordering, like a booking's (PRD §9.3 rule 4).
    service_name_en  text        NOT NULL,
    service_name_bn  text        NOT NULL,
    customer_name    text        NOT NULL,
    customer_phone   text        NOT NULL,
    provider_name    text        NOT NULL,
    provider_phone   text        NOT NULL,
    address_id       uuid        NOT NULL,
    address_area     text        NOT NULL,
    address_line1    text        NOT NULL,
    address_line2    text        NOT NULL DEFAULT '',
    address_lat      double precision NOT NULL,
    address_lng      double precision NOT NULL,
    note             text        NOT NULL DEFAULT '',
    -- The priced lines of one delivery, with the price versions of the order.
    items            jsonb       NOT NULL,
    total_paisa      bigint      NOT NULL CHECK (total_paisa >= 0),
    unit             text        NOT NULL,
    pattern          text        NOT NULL CHECK (pattern IN ('once', 'daily', 'weekdays', 'weekly', 'monthly')),
    weekdays         int[]       NOT NULL DEFAULT '{}',
    day_of_month     int         CHECK (day_of_month BETWEEN 1 AND 31),
    window_start     time        NOT NULL,
    window_end       time        NOT NULL CHECK (window_end > window_start),
    cutoff           time        NOT NULL,
    start_date       date        NOT NULL,
    end_date         date        CHECK (end_date >= start_date),
    count            int         CHECK (count >= 1),
    status           text        NOT NULL CHECK (status IN ('requested', 'active', 'paused', 'finished', 'declined', 'cancelled')),
    decline_reason   text        NOT NULL DEFAULT '',
    idempotency_key  text        NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    accepted_at      timestamptz,
    UNIQUE (customer_id, idempotency_key)
);
CREATE INDEX subscriptions_customer_idx ON booking.subscriptions (customer_id, created_at DESC, id DESC);
CREATE INDEX subscriptions_provider_idx ON booking.subscriptions (provider_id, status, created_at DESC);
CREATE INDEX subscriptions_created_idx ON booking.subscriptions (created_at DESC, id DESC);
-- The delivery sweep reads only active subscriptions.
CREATE INDEX subscriptions_active_idx ON booking.subscriptions (start_date) WHERE status = 'active';

CREATE TABLE booking.subscription_dates (
    subscription_id  uuid        NOT NULL REFERENCES booking.subscriptions (id) ON DELETE CASCADE,
    date             date        NOT NULL,
    state            text        NOT NULL CHECK (state IN ('skipped', 'changed', 'declined', 'cancelled', 'booked')),
    items            jsonb,
    booking_id       uuid        REFERENCES booking.bookings (id),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (subscription_id, date),
    CHECK ((state = 'booked') = (booking_id IS NOT NULL))
);
-- The partner's calendar and the sweep read a date range across subscriptions.
CREATE INDEX subscription_dates_date_idx ON booking.subscription_dates (date);

-- +goose Down
DROP TABLE booking.subscription_dates;
DROP TABLE booking.subscriptions;
DROP SEQUENCE booking.subscription_number_seq;
