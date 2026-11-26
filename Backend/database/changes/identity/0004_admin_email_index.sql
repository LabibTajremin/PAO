-- +goose Up
-- Admin sign-in and `migrate create-admin` look an admin up by lower(email)
-- (IdentityRepository.AdminByEmail). The unique index on email cannot serve that
-- expression, so each sign-in scanned every account, customers and merchants included.
CREATE INDEX accounts_email_lower_idx ON identity.accounts (lower(email)) WHERE email IS NOT NULL;

-- +goose Down
DROP INDEX identity.accounts_email_lower_idx;
