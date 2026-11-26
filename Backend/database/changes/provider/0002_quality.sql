-- +goose Up
-- Provider cancellations after acceptance, counted over 30 days for the quality review
-- (PRD §6.4, D13).
CREATE TABLE provider.cancellations (
    booking_id  uuid PRIMARY KEY,
    provider_id uuid        NOT NULL,
    at          timestamptz NOT NULL
);
CREATE INDEX cancellations_provider_idx ON provider.cancellations (provider_id, at);

-- +goose Down
DROP TABLE provider.cancellations;
