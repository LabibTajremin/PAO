# shellcheck shell=bash
# Code generation (sqlc, oapi-codegen, mockgen, Dart API client, l10n) and the
# "generated code is committed" check used by CI.

REDOCLY_CLI="@redocly/cli@1.34.3"
SPEC_BUNDLE="backend/internal/platform/httpx/api/openapi.gen.yaml"

# gen_spec bundles the split api/ files into the single document the generators and
# the request validator read.
gen_spec() {
  [[ -f "$PAO_ROOT/api/openapi.yaml" ]] || return 0
  require_tool npx "install Node.js 22"
  (cd "$PAO_ROOT" && npx --yes "$REDOCLY_CLI" bundle api/openapi.yaml -o "$SPEC_BUNDLE" >/dev/null 2>&1) ||
    die "OpenAPI bundle failed"
}

gen_go() {
  [[ -f "$BACKEND/go.mod" ]] || return 0
  if [[ -f "$BACKEND/sqlc.yaml" ]]; then
    require_tool sqlc "go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.27.0"
    (cd "$BACKEND" && sqlc generate) || die "sqlc generate failed"
  fi
  if grep -rqs --include='*.go' '^//go:generate' "$BACKEND"; then
    (cd "$BACKEND" && go generate ./...) || die "go generate failed"
  fi
}

gen_dart_client() {
  [[ -f "$PAO_ROOT/api/openapi.yaml" && -d "$FRONTEND/packages/pao_api" ]] || return 0
  require_tool docker "https://docs.docker.com/engine/install/"
  "$PAO_ROOT/scripts/gen-dart-client.sh" || die "Dart client generation failed"
}

gen_l10n() {
  [[ -f "$FRONTEND/packages/pao_l10n/l10n.yaml" ]] || return 0
  (cd "$FRONTEND/packages/pao_l10n" && flutter gen-l10n >/dev/null) || die "flutter gen-l10n failed"
}

# tree_fingerprint hashes every modified or untracked file, so a generator run that
# changes anything is detected even before the work is committed.
tree_fingerprint() {
  (cd "$PAO_ROOT" && git ls-files -m -o --exclude-standard -z | xargs -0 -r sha1sum | sha1sum)
}

cmd_gen() {
  local before
  before=$(tree_fingerprint)
  gen_spec
  gen_go
  gen_dart_client
  gen_l10n
  if [[ "${CI:-}" == "true" || "${1:-}" == "--check" ]]; then
    [[ "$(tree_fingerprint)" == "$before" ]] || {
      git -C "$PAO_ROOT" status --short >&2
      die "generated code is out of date; run ./pao gen and commit"
    }
  fi
  ok "generated code up to date"
}
