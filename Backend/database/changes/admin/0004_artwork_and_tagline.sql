-- +goose Up
-- Admin-managed illustrations (06-update §5, ADR-0040). A slot without a row shows the
-- illustration the app bundles. `migrate seed` fills seed_url and, unless an admin replaced the
-- image (replaced), url; resetting a slot puts seed_url back. Files live in the public bucket.
CREATE TABLE admin.artwork_slots (
    key          text        PRIMARY KEY,
    url          text        CHECK (url IS NULL OR url ~ '^https?://'),
    content_type text,
    seed_url     text        CHECK (seed_url IS NULL OR seed_url ~ '^https?://'),
    version      int         NOT NULL DEFAULT 0,
    replaced     boolean     NOT NULL DEFAULT false,
    updated_at   timestamptz NOT NULL DEFAULT now(),
    updated_by   uuid
);

-- The tagline on splash, sign-in, share text and receipts (06-update §6).
INSERT INTO admin.settings (key, value, type, description) VALUES
    ('brand.tagline', '{"en":"Ask for it. PAO it.","bn":"যা চাও, তাই PAO"}', 'tagline',
     'Tagline in English and Bangla, at most 40 characters each');

-- +goose Down
DELETE FROM admin.settings WHERE key = 'brand.tagline';
DROP TABLE admin.artwork_slots;
