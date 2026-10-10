#!/usr/bin/env bash
# Regenerates frontend/packages/pao_api from the bundled OpenAPI spec with the pinned
# openapi-generator image, then runs build_runner for the JSON serializers. OpenAPI
# `format: date` maps to String: DateTime would serialise with a time part the API
# rejects.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
image="${OPENAPI_GENERATOR_IMAGE:-openapitools/openapi-generator-cli:v7.16.0}"
spec="backend/internal/platform/httpx/api/openapi.gen.yaml"
out="frontend/packages/pao_api"

find "$root/$out/lib" -name '*.dart' -delete 2>/dev/null || true
docker run --rm -u "$(id -u):$(id -g)" -v "$root:/work" "$image" generate \
  -i "/work/$spec" -g dart-dio -o "/work/$out" \
  --global-property apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
  --type-mappings=date=String \
  --additional-properties=pubName=pao_api,serializationLibrary=json_serializable,dateLibrary=core,equalityCheckMethod=equatable \
  >/dev/null
rm -rf "$root/$out/doc" "$root/$out/test"
(cd "$root/frontend" && flutter pub get >/dev/null)
(cd "$root/$out" && dart run build_runner build --delete-conflicting-outputs >/dev/null)
dart format "$root/$out/lib" >/dev/null
