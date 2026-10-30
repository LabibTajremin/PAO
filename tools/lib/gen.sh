# shellcheck shell=bash
# Code generation (the bundled OpenAPI document the backend serves, the Dart API client,
# l10n) and the "generated code is committed" check used by CI.

# gen_backend bundles Backend/Api/openapi.yaml into the document the HTTP edge matches and
# validates against; the Dart client is generated from the same bundle.
gen_backend() {
  [[ -f "$BACKEND/Api/openapi.yaml" ]] || return 0
  require_tool npx "https://nodejs.org (npx runs the pinned Redocly CLI)"
  require_dotnet
  "$BACKEND/scripts/gen-spec.sh" >/dev/null || die "OpenAPI bundling failed"
}

gen_dart_client() {
  [[ -f "$BACKEND/Api/openapi.yaml" && -d "$FRONTEND/packages/pao_api" ]] || return 0
  require_tool docker "https://docs.docker.com/engine/install/"
  "$PAO_ROOT/tools/gen-dart-client.sh" || die "Dart client generation failed"
}

gen_l10n() {
  local cfg
  while IFS= read -r cfg; do
    (cd "$(dirname "$cfg")" && flutter gen-l10n >/dev/null) || die "flutter gen-l10n failed in ${cfg%/l10n.yaml}"
  done < <(find "$FRONTEND/packages" "$FRONTEND/apps" -maxdepth 2 -name l10n.yaml 2>/dev/null)
}

# tree_fingerprint hashes every modified or untracked file, so a generator run that
# changes anything is detected even before the work is committed.
tree_fingerprint() {
  # Deleted files are listed as modified but cannot be hashed; their absence is
  # already part of the git state.
  (cd "$PAO_ROOT" && git ls-files -m -o --exclude-standard -z |
    while IFS= read -r -d '' f; do [[ ! -f "$f" ]] || sha1sum "$f"; done | sha1sum)
}

cmd_gen() {
  local before
  before=$(tree_fingerprint)
  gen_backend
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
