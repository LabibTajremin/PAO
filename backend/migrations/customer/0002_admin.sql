-- +goose Up
-- Copies kept current for the admin customer list (A-05, PRD §9.3 rule 4).
ALTER TABLE customer.customers
    ADD COLUMN phone          text NOT NULL DEFAULT '',
    ADD COLUMN account_status text NOT NULL DEFAULT 'active',
    ADD COLUMN bookings       int  NOT NULL DEFAULT 0;
CREATE INDEX customers_created_idx ON customer.customers (created_at DESC, id DESC);

-- +goose Down
DROP INDEX customer.customers_created_idx;
ALTER TABLE customer.customers DROP COLUMN phone, DROP COLUMN account_status, DROP COLUMN bookings;
