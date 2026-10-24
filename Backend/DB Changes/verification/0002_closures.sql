-- +goose Up
-- Accounts closed by their owners: their verification records and documents stay for
-- the retention period (ADR-0023, setting documents.retention_days), then are purged.
CREATE TABLE verification.closed_accounts (
    provider_id uuid PRIMARY KEY,
    closed_at   timestamptz NOT NULL
);
CREATE INDEX closed_accounts_closed_idx ON verification.closed_accounts (closed_at);

-- +goose Down
DROP TABLE verification.closed_accounts;
