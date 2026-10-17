-- +goose Up
-- Identity: accounts, admin credentials, roles, permissions and screen permissions.
CREATE SCHEMA identity;

CREATE TABLE identity.accounts (
    id         uuid PRIMARY KEY,
    phone      text UNIQUE,
    email      text UNIQUE,
    name       text NOT NULL DEFAULT '',
    status     text NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'suspended', 'banned')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CHECK (phone IS NOT NULL OR email IS NOT NULL OR deleted_at IS NOT NULL)
);

CREATE TABLE identity.roles (
    name        text PRIMARY KEY,
    description text    NOT NULL,
    is_admin    boolean NOT NULL
);

CREATE TABLE identity.account_roles (
    account_id uuid NOT NULL REFERENCES identity.accounts (id) ON DELETE CASCADE,
    role       text NOT NULL REFERENCES identity.roles (name),
    granted_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, role)
);

CREATE TABLE identity.admin_credentials (
    account_id           uuid PRIMARY KEY REFERENCES identity.accounts (id) ON DELETE CASCADE,
    password_hash        text        NOT NULL,
    must_change_password boolean     NOT NULL DEFAULT true,
    totp_secret_enc      bytea,
    totp_enrolled        boolean     NOT NULL DEFAULT false,
    failed_attempts      int         NOT NULL DEFAULT 0,
    locked_until         timestamptz,
    active               boolean     NOT NULL DEFAULT true,
    last_login_at        timestamptz
);

-- Phones of banned identities cannot sign up again (PRD §6.4).
CREATE TABLE identity.blocked_phones (
    phone      text PRIMARY KEY,
    reason     text        NOT NULL,
    blocked_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE identity.permissions (
    name        text PRIMARY KEY,
    description text NOT NULL
);

CREATE TABLE identity.role_permissions (
    role       text NOT NULL REFERENCES identity.roles (name) ON DELETE CASCADE,
    permission text NOT NULL REFERENCES identity.permissions (name) ON DELETE CASCADE,
    PRIMARY KEY (role, permission)
);

CREATE TABLE identity.screens (
    id  text PRIMARY KEY,
    app text NOT NULL CHECK (app IN ('customer', 'partner', 'admin')),
    name text NOT NULL
);

CREATE TABLE identity.role_screens (
    role      text NOT NULL REFERENCES identity.roles (name) ON DELETE CASCADE,
    screen_id text NOT NULL REFERENCES identity.screens (id) ON DELETE CASCADE,
    PRIMARY KEY (role, screen_id)
);

-- Events written in the same transaction as the change; the relay delivers them
-- at least once, in order per aggregate (PRD §9.3 rule 5).
CREATE TABLE identity.outbox (
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
CREATE INDEX outbox_pending_idx ON identity.outbox (next_attempt_at, created_at) WHERE published_at IS NULL AND NOT dead;

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE identity.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA identity CASCADE;
