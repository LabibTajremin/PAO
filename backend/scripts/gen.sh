#!/usr/bin/env bash
# Regenerates the committed generated code of the NestJS backend (ADR-0032):
#   - sqlc query functions in src/modules/<m>/adapter/postgres/sqlc/ (sqlc.yaml);
#   - the bundled OpenAPI document the HTTP edge validates against;
#   - TypeScript types for that document (openapi-typescript).
# Output is deterministic, so running it twice yields no diff; CI regenerates and
# fails when the committed files differ.
set -euo pipefail

NEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_SOURCE="$NEST_ROOT/../api/openapi.yaml"
SPEC_BUNDLE="src/platform/http/openapi.gen.yaml"
SPEC_TYPES="src/platform/http/openapi.gen.ts"
REDOCLY_CLI="@redocly/cli@1.34.3"

die() {
  echo "gen: $*" >&2
  exit 1
}

gen_sqlc() {
  command -v sqlc >/dev/null || die "sqlc missing: go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.27.0"
  sqlc generate || die "sqlc generate failed"
  # sqlc-gen-typescript reads the single row of a :one query as result.rows[0] right
  # after checking rows.length === 1; the strict tsconfig (noUncheckedIndexedAccess)
  # cannot see that guard, so the access is asserted non-null.
  local file
  while IFS= read -r -d '' file; do
    sed -i 's/const row = result\.rows\[0\];/const row = result.rows[0]!;/' "$file"
  done < <(find src/modules -path '*/adapter/postgres/sqlc/*.ts' -print0)
}

gen_spec() {
  [[ -f "$SPEC_SOURCE" ]] || die "missing $SPEC_SOURCE"
  mkdir -p "$(dirname "$SPEC_BUNDLE")"
  npx --yes "$REDOCLY_CLI" bundle "$SPEC_SOURCE" -o "$SPEC_BUNDLE" >/dev/null 2>&1 ||
    die "OpenAPI bundle failed"
  npx openapi-typescript "$SPEC_BUNDLE" -o "$SPEC_TYPES" >/dev/null 2>&1 ||
    die "openapi-typescript failed"
}

cd "$NEST_ROOT"
gen_sqlc
gen_spec
