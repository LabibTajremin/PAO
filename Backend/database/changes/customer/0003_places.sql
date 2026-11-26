-- +goose Up
-- OpenStreetMap places for Dhaka (ADR-0042), loaded by `migrate import-places`. search_text is
-- the English and Bangla names in lower case with Bangla digits as ASCII digits, so
-- "গুলশান ২" and "gulshan 2" meet in one trigram index.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE customer.places (
    id          text        PRIMARY KEY,
    kind        text        NOT NULL CHECK (kind IN ('area', 'street', 'place', 'address')),
    name_en     text        NOT NULL,
    name_bn     text        NOT NULL DEFAULT '',
    area        text        NOT NULL DEFAULT '',
    search_text text        NOT NULL,
    location    geography(Point, 4326) NOT NULL
);
CREATE INDEX places_search_idx ON customer.places USING gin (search_text gin_trgm_ops);
CREATE INDEX places_location_idx ON customer.places USING gist (location);

-- +goose Down
DROP TABLE customer.places;
