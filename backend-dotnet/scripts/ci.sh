#!/usr/bin/env bash
# The .NET quality gates (ADR-0034): build (warnings as errors, XML docs), format,
# architecture/size/docs gates, unit + integration tests with merged 100% line coverage,
# the bundled-spec check and the start-up smoke tests.
# Usage: ci.sh [build|format|spec|gates|test|e2e|all]
set -euo pipefail

DOTNET_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/root/.dotnet:$PATH" DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
cd "$DOTNET_ROOT_DIR"

step() { printf '\033[1;34m▸\033[0m %s\n' "$*" >&2; }

ci_build() {
  step "dotnet build (warnings as errors)"
  dotnet build PAO.sln -warnaserror -nologo -v quiet
}

ci_spec() {
  step "bundled OpenAPI document is up to date"
  scripts/gen-spec.sh --check
}

ci_format() {
  step "dotnet format --verify-no-changes"
  dotnet format PAO.sln --verify-no-changes
}

ci_gates() {
  step "architecture, authorisation, size and docs gates"
  dotnet test --project Test/PAO.UnitTests --no-build -- --filter-trait "Category=Gate"
}

ci_test() {
  local out="$DOTNET_ROOT_DIR/coverage" settings="$DOTNET_ROOT_DIR/coverage.config"
  rm -rf "$out" && mkdir -p "$out"
  step "unit tests with coverage"
  dotnet test --project Test/PAO.UnitTests --no-build -- --coverage --coverage-output-format cobertura \
    --coverage-output "$out/unit.cobertura.xml" --coverage-settings "$settings"
  step "integration tests with coverage (Postgres, Redis, S3 from PAO_TEST_* or compose)"
  dotnet test --project Test/PAO.IntegrationTests --no-build -- --coverage --coverage-output-format cobertura \
    --coverage-output "$out/integration.cobertura.xml" --coverage-settings "$settings"
  step "merged coverage gate (100% of hand-written lines)"
  python3 -I scripts/coverage.py "$out/summary.md" "$out/unit.cobertura.xml" "$out/integration.cobertura.xml"
}

ci_e2e() {
  step "start-up smoke tests"
  dotnet test --project Test/PAO.E2ETests --no-build -- --filter-not-trait "Category=Journey"
}

# Stages run as separate statements, never chained with && or ||: bash ignores set -e
# inside any function called from such a list, which once let failing tests exit 0.
run() {
  local stage
  for stage in "$@"; do
    "ci_$stage"
  done
}

case "${1:-all}" in
  build) run build ;;
  format) run format ;;
  spec) run spec ;;
  gates) run build gates ;;
  test) run build test ;;
  e2e) run build e2e ;;
  all) run build format spec gates test e2e ;;
  *)
    echo "usage: ci.sh [build|format|spec|gates|test|e2e|all]" >&2
    exit 2
    ;;
esac
