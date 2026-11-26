# Dhaka places (OpenStreetMap)

The apps search addresses and name map pins from PAO's own copy of OpenStreetMap, so no
Google key or per-search bill exists (ADR-0042). This guide builds that copy and keeps it
fresh.

## What you need

- `osmium-tool` and `curl` (Ubuntu: `apt-get install osmium-tool`).
- The production `DATABASE_URL` in the shell, as for `migrate up`.
- About 1 GB free disk for the Bangladesh extract.

## First import and monthly refresh

```bash
tools/places/build.sh out/places
```

```bash
docker run --rm -e DATABASE_URL -v "$PWD/out/places:/places" <api-image> /app/migrate import-places /places/dhaka-places.geojsonseq
```

`build.sh` downloads Geofabrik's Bangladesh extract, clips it to the Dhaka box
(`PAO_PLACES_BBOX`, default `90.30,23.65,90.52,23.90`, as west,south,east,north) and keeps named
areas, streets, places and house addresses. The import replaces the whole table in one
transaction, so a failed or repeated run leaves the old places or the new ones, never a mix.
Searches are cached for a day, so a refresh shows within a day.

Run both commands once a month; OpenStreetMap is updated daily, but Dhaka's names change slowly.
When PAO opens a new city, widen `PAO_PLACES_BBOX` (or run with a second box and merge the
files) and extend the launch area in the admin settings.

## Attribution

OpenStreetMap data is under the ODbL. Every map frame in the apps shows
"© OpenStreetMap contributors"; keep that line if the map is redesigned.

## Tiles (later)

`tools/places/tiles.sh` turns the same clip into `dhaka.pmtiles` (needs Java 21) and, with
`PAO_TILES_BUCKET` set, uploads it to `maps/dhaka.pmtiles` in that bucket. The apps still pin on
a plain frame; drawing these tiles needs a map renderer, which is the owner's call.

## Local development

`migrate seed` loads `Backend/database/seed/places-sample.geojsonseq` (a dozen Dhaka places)
outside production when the table is empty, so search works in dev and the e2e stack.
