# ADR-0042: OpenStreetMap places for Dhaka, served by PAO

- Status: Accepted
- Date: 2026-11-25
- Source: owner requirement iii (06-update-2026-11.md §7), phase P26.

## Context

Address search and the map pin used the Google Geocoding API behind the maps port (D10). It
costs money per call, and copying Google's data is against its terms. OpenStreetMap data is
free under the ODbL, which only asks for the attribution "© OpenStreetMap contributors".

## Decision

1. **Places table.** `customer.places` holds Dhaka's named areas, streets, points of interest
   and addresses with English and Bangla names, a point, the nearest area, and a normalised
   `search_text` (lower case, Bangla digits as ASCII digits) with a `pg_trgm` index. It
   belongs to the Customer area, which already owns addresses and PostGIS; no new schema.
2. **Import.** `migrate import-places FILE` loads a GeoJSON-sequence file made by
   `tools/places/build.sh` (Geofabrik's Bangladesh extract, clipped to the Dhaka bounding box
   with osmium, filtered to named features and addresses, exported with `osmium export`). It
   replaces the table's rows in one transaction, so a rerun is safe; a monthly refresh is the
   same two commands. The bounding box is the script's `PAO_PLACES_BBOX`.
3. **API.** `GET /v1/places/search?q=&lat=&lng=` ranks by `word_similarity` on the search
   text, then by kind (areas, streets, places, addresses) and distance to the optional point;
   `GET /v1/places/reverse?lat=&lng=` answers the nearest place within 300 m, and
   `OUTSIDE_SERVICE_AREA` outside the launch area. Both need a signed-in account of any
   app (`catalog:read`, like the launch-area check), are rate-limited like every endpoint, and
   are cached in Redis for a day.
4. **Apps.** The Google adapter and the `PAO_MAPS_API_KEY` define are removed; the PAO
   adapter sits behind the same port. Every map frame shows "© OpenStreetMap contributors".
5. **Tiles.** `tools/places/tiles.sh` builds a Dhaka PMTiles file with planetiler from the
   same extract and uploads it to the public bucket. The apps keep the pin-on-a-frame picker
   until a map renderer is chosen: MapLibre is a native plugin the widget tests and the Linux
   desktop journeys cannot run, so drawing the tiles in the apps is left to the owner's call.

## Consequences

- No call leaves PAO for a search or a pin.
- The data is as fresh as the last import; the guide says how to refresh it.
