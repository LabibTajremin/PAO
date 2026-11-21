-- +goose Up
-- An admin may give a category or service its own icon, uploaded or added from a link and
-- stored in our public bucket (ADR-0039). When set, the apps show it instead of the library
-- icon named by icon_key, which stays as the fallback.
ALTER TABLE catalog.categories ADD COLUMN icon_url text CHECK (icon_url IS NULL OR icon_url ~ '^https?://');
ALTER TABLE catalog.services ADD COLUMN icon_url text CHECK (icon_url IS NULL OR icon_url ~ '^https?://');

-- +goose Down
ALTER TABLE catalog.services DROP COLUMN icon_url;
ALTER TABLE catalog.categories DROP COLUMN icon_url;
