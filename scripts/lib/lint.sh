# shellcheck shell=bash
# Static checks: formatting, linters, architecture rules and file-size limits.

# size_limit prints the line limit of docs/build/01-conventions.md §1 for a file.
size_limit() {
  case "$1" in
    *.spec.ts | *.int-spec.ts | */backend/test/*.ts) echo 400 ;;
    *.ts) echo 250 ;;
    */test/*.dart | */integration_test/*.dart) echo 300 ;;
    *.dart) echo 200 ;;
  esac
}

# hand_written lists the TypeScript and Dart sources the size limits apply to;
# generated code is left out.
hand_written() {
  find "$BACKEND" "$E2E_API" "$FRONTEND" \( -name '*.ts' -o -name '*.dart' \) \
    -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' \
    -not -path '*/sqlc/*' -not -name '*.gen.*' -not -name '*.d.ts' \
    -not -path '*/.dart_tool/*' -not -path '*/build/*' -not -path '*/pao_api/*' \
    -not -name '*.g.dart' -not -path '*/l10n/generated/*' 2>/dev/null
}

check_file_sizes() {
  local failed=0 file lines limit
  while IFS= read -r file; do
    lines=$(wc -l <"$file")
    limit=$(size_limit "$file")
    if ((lines > limit)); then
      printf '  %s: %d lines (limit %d)\n' "${file#"$PAO_ROOT"/}" "$lines" "$limit" >&2
      failed=1
    fi
  done < <(hand_written)
  ((failed == 0)) || die "file-size check failed"
  ok "file sizes within limits"
}

# lint_backend runs ESLint, Prettier, the module boundary rules and the type check on
# the backend, and the same rules on the black-box API journeys.
lint_backend() {
  [[ -f "$BACKEND/package.json" ]] || return 0
  npm_install "$BACKEND"
  (cd "$BACKEND" && npm run -s lint && npm run -s typecheck) || die "backend lint failed"
  if [[ -f "$E2E_API/package.json" ]]; then
    npm_install "$E2E_API"
    (cd "$E2E_API" && npm run -s lint) || die "e2e journey lint failed"
  fi
  ok "backend lint, types and module boundaries"
}

lint_dart() {
  [[ -f "$FRONTEND/pubspec.yaml" ]] || return 0
  require_tool flutter "https://docs.flutter.dev/get-started/install"
  (cd "$FRONTEND" && flutter pub get >/dev/null &&
    dart format --output=none --set-exit-if-changed . >/dev/null &&
    dart analyze --fatal-infos . >/dev/null) || die "Dart format/analyze failed"
  local pkg
  while IFS= read -r pkg; do
    [[ "${pkg##*/}" == pao_api ]] && continue
    (cd "$pkg" && dart run dart_code_linter:metrics analyze lib --fatal-style \
      --fatal-performance --fatal-warnings >/dev/null) || die "dart_code_linter failed in $pkg"
  done < <(dart_packages)
  ok "Dart format, analyze and metrics"
}

lint_shell() {
  require_tool shellcheck "apt install shellcheck"
  shellcheck "$PAO_ROOT/pao" "$PAO_ROOT"/scripts/*.sh "$PAO_ROOT"/scripts/lib/*.sh \
    "$PAO_ROOT"/scripts/hooks/* "$PAO_ROOT"/test/e2e/*.sh "$PAO_ROOT"/test/e2e/mobile/*.sh \
    "$BACKEND"/scripts/*.sh || die "shellcheck failed"
  ok "shellcheck"
}

# cmd_lint runs every check, or one scope for the CI jobs and the pre-commit hook.
cmd_lint() {
  case "${1:-all}" in
    backend) check_file_sizes && lint_backend ;;
    dart) check_file_sizes && lint_dart ;;
    shell) lint_shell ;;
    sizes) check_file_sizes ;;
    all) check_file_sizes && lint_shell && lint_backend && lint_dart ;;
    *) die "usage: pao lint [backend|dart|shell|sizes|all]" ;;
  esac
}
