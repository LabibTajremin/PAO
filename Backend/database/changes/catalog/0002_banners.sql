-- +goose Up
-- Home banners (C07): admins add, order and publish them in the panel; the customer home
-- shows the published ones above the categories. A banner may open a service and may
-- carry an image; without one the app draws it in the accent's deep colour.
CREATE TABLE catalog.banners (
    id          uuid PRIMARY KEY,
    title_en    text        NOT NULL,
    title_bn    text        NOT NULL,
    subtitle_en text,
    subtitle_bn text,
    CHECK ((subtitle_en IS NULL) = (subtitle_bn IS NULL)),
    image_url   text        CHECK (image_url IS NULL OR image_url LIKE 'https://%'),
    service_id  uuid        REFERENCES catalog.services (id),
    sort_order  int         NOT NULL DEFAULT 0,
    published   boolean     NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX banners_published_idx ON catalog.banners (sort_order) WHERE published;

-- A demo banner so a fresh install shows one; admins edit or unpublish it.
INSERT INTO catalog.banners (id, title_en, title_bn, subtitle_en, subtitle_bn, sort_order, published)
VALUES ('5b7a1f2e-0c9d-4e3a-8b6f-2d1c0e9f8a71',
        'Home services, at your door',
        'ঘরের সেবা, আপনার দোরগোড়ায়',
        'Verified professionals. Pay in cash after the work.',
        'যাচাই করা পেশাদার। কাজ শেষে নগদে পরিশোধ।',
        0, true);

-- +goose Down
DROP TABLE catalog.banners;
