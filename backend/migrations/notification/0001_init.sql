-- +goose Up
-- Notification: in-app inbox and device tokens (C-13, P-12).
CREATE SCHEMA notification;

CREATE TABLE notification.notifications (
    id           uuid PRIMARY KEY,
    recipient_id uuid        NOT NULL,
    app          text        NOT NULL CHECK (app IN ('customer', 'partner')),
    type         text        NOT NULL,
    title        text        NOT NULL,
    body         text        NOT NULL,
    booking_id   uuid,
    dedupe_key   text        NOT NULL,
    read_at      timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now(),
    UNIQUE (recipient_id, dedupe_key)
);
CREATE INDEX notifications_inbox_idx ON notification.notifications (recipient_id, app, created_at DESC, id DESC);
CREATE INDEX notifications_unread_idx ON notification.notifications (recipient_id, app) WHERE read_at IS NULL;

CREATE TABLE notification.device_tokens (
    token      text PRIMARY KEY,
    account_id uuid        NOT NULL,
    app        text        NOT NULL CHECK (app IN ('customer', 'partner')),
    platform   text        NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX device_tokens_account_idx ON notification.device_tokens (account_id, app);

-- Recipient language, copied from profile events, so templates render without calls.
CREATE TABLE notification.recipients (
    account_id uuid PRIMARY KEY,
    language   text NOT NULL DEFAULT 'bn' CHECK (language IN ('en', 'bn'))
);

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE notification.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA notification CASCADE;
