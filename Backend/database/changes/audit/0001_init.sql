-- +goose Up
-- Audit: the append-only trail of decisions and status changes (PRD §6.4, A-08).
CREATE SCHEMA audit;

CREATE TABLE audit.entries (
    id           uuid PRIMARY KEY,
    at           timestamptz NOT NULL DEFAULT now(),
    actor_id     uuid,
    actor_role   text        NOT NULL DEFAULT '',
    action       text        NOT NULL,
    subject_type text        NOT NULL,
    subject_id   text        NOT NULL,
    reason       text        NOT NULL DEFAULT '',
    before       jsonb,
    after        jsonb,
    event_id     uuid UNIQUE
);
CREATE INDEX entries_at_idx ON audit.entries (at DESC, id DESC);
CREATE INDEX entries_subject_idx ON audit.entries (subject_type, subject_id, at DESC);
CREATE INDEX entries_actor_idx ON audit.entries (actor_id, at DESC);
CREATE INDEX entries_action_idx ON audit.entries (action, at DESC);

-- +goose StatementBegin
CREATE FUNCTION audit.reject_change() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit entries are append-only';
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd
CREATE TRIGGER entries_append_only BEFORE UPDATE OR DELETE ON audit.entries
    FOR EACH ROW EXECUTE FUNCTION audit.reject_change();
-- TRUNCATE bypasses row triggers, so it is blocked separately.
CREATE TRIGGER entries_no_truncate BEFORE TRUNCATE ON audit.entries
    FOR EACH STATEMENT EXECUTE FUNCTION audit.reject_change();

-- Handlers record events they have applied so redelivery is harmless.
CREATE TABLE audit.processed_events (
    handler      text        NOT NULL,
    event_id     uuid        NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (handler, event_id)
);

-- +goose Down
DROP SCHEMA audit CASCADE;
