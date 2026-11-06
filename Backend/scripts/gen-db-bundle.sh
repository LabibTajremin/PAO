#!/usr/bin/env bash
# Regenerates the single-file database scripts "DB Changes/bundle/schema.sql" and
# "seed.sql" from the goose migrations and Seed/catalog.yaml (`migrate bundle`). With
# --check (or CI=true) it only compares and fails when they are out of date.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/root/.dotnet:$PATH" DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1

check=""
if [[ "${1:-}" == --check || "${CI:-}" == true ]]; then
  check=--check
fi
PAO_HOME="$ROOT" dotnet run --project "$ROOT/PAO.Migrator/PAO.Migrator.csproj" --no-launch-profile -v quiet -- bundle ${check:+"$check"}
