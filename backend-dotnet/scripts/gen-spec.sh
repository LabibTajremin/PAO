#!/usr/bin/env bash
# Bundles the OpenAPI contract into PAO.Core/Spec/openapi.gen.yaml, the document the HTTP
# edge matches and validates against. The contract's folder is the MSBuild property
# PaoApiDir (Directory.Build.props), its only definition, so moving api/ to Backend/Api
# at cut-over is a one-line change. With --check (or CI=true) it fails on drift.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REDOCLY_CLI="@redocly/cli@1.34.3"
BUNDLE="$ROOT/PAO.Core/Spec/openapi.gen.yaml"
export PATH="/root/.dotnet:$PATH" DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1

api_dir=$(dotnet msbuild "$ROOT/PAO.Core/PAO.Core.csproj" -getProperty:PaoApiDir)
source="$api_dir/openapi.yaml"
[[ -f "$source" ]] || { echo "gen-spec: missing $source" >&2; exit 1; }

out=$(mktemp --suffix=.yaml)
trap 'rm -f "$out"' EXIT
npx --yes "$REDOCLY_CLI" bundle "$source" -o "$out" >/dev/null 2>&1 || { echo "gen-spec: bundle failed" >&2; exit 1; }
if [[ "${1:-}" == --check || "${CI:-}" == true ]]; then
  cmp -s "$out" "$BUNDLE" || { echo "gen-spec: $BUNDLE is out of date; run scripts/gen-spec.sh" >&2; exit 1; }
  echo "gen-spec: bundle up to date"
else
  cp "$out" "$BUNDLE"
  echo "gen-spec: wrote $BUNDLE"
fi
