#!/usr/bin/env bash
# build.sh — the Dhaka places file for `migrate import-places` (ADR-0042).
#
#   tools/places/build.sh [out-dir]
#
# Downloads Geofabrik's Bangladesh extract, clips it to PAO_PLACES_BBOX (west,south,east,north),
# keeps named areas, streets and points of interest plus house addresses, and writes
# <out-dir>/dhaka-places.geojsonseq. Needs curl and osmium-tool. Then, against the target
# database: `migrate import-places <out-dir>/dhaka-places.geojsonseq`.
set -euo pipefail

out="${1:-out/places}"
bbox="${PAO_PLACES_BBOX:-90.30,23.65,90.52,23.90}"
source_url="${PAO_PLACES_SOURCE:-https://download.geofabrik.de/asia/bangladesh-latest.osm.pbf}"
command -v osmium >/dev/null || { echo "osmium-tool is required (apt-get install osmium-tool)" >&2 && exit 2; }
mkdir -p "$out"

curl -fsSL --retry 3 -o "$out/bangladesh.osm.pbf" "$source_url"
osmium extract --overwrite -b "$bbox" -o "$out/dhaka.osm.pbf" "$out/bangladesh.osm.pbf"
# Areas, streets and the place tags PlaceFeatures reads; untagged nodes never reach the export.
osmium tags-filter --overwrite -o "$out/dhaka-named.osm.pbf" "$out/dhaka.osm.pbf" \
  nwr/place=suburb,neighbourhood,quarter,city_block,locality,village \
  w/highway nwr/amenity nwr/shop nwr/office nwr/tourism nwr/leisure nwr/healthcare nwr/craft \
  nwr/building nwr/addr:housenumber
osmium export --overwrite -f geojsonseq --add-unique-id=type_id -o "$out/dhaka-places.geojsonseq" "$out/dhaka-named.osm.pbf"
echo "places: $(wc -l <"$out/dhaka-places.geojsonseq") features in $out/dhaka-places.geojsonseq"
