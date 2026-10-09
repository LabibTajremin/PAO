# shellcheck shell=bash
# Code generation (sqlc, oapi-codegen, mockgen, Dart API client, l10n) and the
# "generated code is committed" check used by CI.

OPENAPI_GENERATOR_VERSION=7.10.0
OPENAPI_GENERATOR_JAR="${XDG_CACHE_HOME:-$HOME/.cache}/pao/openapi-generator-cli-$OPENAPI_GENERATOR_VERSION.jar"

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

openapi_generator_jar() {
  [[ -f "$OPENAPI_GENERATOR_JAR" ]] && return 0
  mkdir -p "$(dirname "$OPENAPI_GENERATOR_JAR")"
  retry curl -fsSL -o "$OPENAPI_GENERATOR_JAR" \
    "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$OPENAPI_GENERATOR_VERSION/openapi-generator-cli-$OPENAPI_GENERATOR_VERSION.jar"
}

gen_dart_client() {
  [[ -f "$PAO_ROOT/api/openapi.yaml" && -d "$FRONTEND/packages/pao_api" ]] || return 0
  require_tool java "install a JDK (17+)"
  openapi_generator_jar || die "could not download openapi-generator"
  "$PAO_ROOT/scripts/gen-dart-client.sh" "$OPENAPI_GENERATOR_JAR" || die "Dart client generation failed"
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
