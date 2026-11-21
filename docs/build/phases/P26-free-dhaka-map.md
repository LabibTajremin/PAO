# P26 — Free Dhaka map (OpenStreetMap)

**Goal:** address search and map pins work for Dhaka with no paid map API.

**Read first:** `06-update-2026-11.md` §7 (why not Google scraping); customer `location/`
(`google_places.dart`, maps port); `pao_ui` `map_frame.dart`; PostGIS setup.

## Tasks

1. `migrate import-places`: download the Geofabrik Bangladesh extract, clip to the Dhaka
   bounding box (configurable) with osmium, load POIs, streets, areas and addresses with en/bn
   names into `geo.places` (PostGIS + `pg_trgm` index). Idempotent; documented monthly refresh.
2. Backend `GET /v1/places/search?q=&near=` and `GET /v1/places/reverse?lat=&lng=`, Dhaka only,
   rate-limited, cached in Redis.
3. Tiles: a script builds a Dhaka PMTiles file (planetiler) and uploads it to the bucket; the
   apps render it with MapLibre and a palette style (light and dark). Attribution "© OpenStreetMap
   contributors" visible on every map.
4. Replace the Google Places adapter with the PAO places adapter behind the existing port;
   remove the Google Places key and docs references. Outside Dhaka: a friendly "coming soon".
5. Tests: import on a small fixture extract, search ranking (Bangla and English), adapter tests,
   e2e pin-and-search journey.

## Definition of done

A customer can search "Dhanmondi 27", "গুলশান ২" or a shop name and drop a pin, with zero calls
to Google. `./pao ci` green.
