#!/usr/bin/env bash
# tiles.sh — a Dhaka PMTiles basemap for a future in-app map renderer (ADR-0042 §5).
#
#   tools/places/tiles.sh [out-dir]
#
# Builds <out-dir>/dhaka.pmtiles with planetiler (Java 21+) from the clip build.sh made, then,
# with PAO_TILES_BUCKET set, copies it to s3://$PAO_TILES_BUCKET/maps/dhaka.pmtiles with the
# AWS CLI (any S3-compatible store; set AWS_ENDPOINT_URL for R2 or MinIO). The apps do not draw
# tiles yet; this keeps the file ready for when a renderer is chosen.
set -euo pipefail

out="${1:-out/places}"
planetiler="${PAO_PLANETILER_JAR:-$out/planetiler.jar}"
[[ -f "$out/dhaka.osm.pbf" ]] || { echo "run tools/places/build.sh first" >&2 && exit 2; }
[[ -f "$planetiler" ]] || curl -fsSL --retry 3 -o "$planetiler" \
  https://github.com/onthegomap/planetiler/releases/download/v0.8.4/planetiler.jar

java -Xmx2g -jar "$planetiler" --osm-path="$out/dhaka.osm.pbf" --output="$out/dhaka.pmtiles" \
  --download --force --maxzoom=15
if [[ -n "${PAO_TILES_BUCKET:-}" ]]; then
  aws s3 cp "$out/dhaka.pmtiles" "s3://$PAO_TILES_BUCKET/maps/dhaka.pmtiles" --content-type application/vnd.pmtiles
fi
