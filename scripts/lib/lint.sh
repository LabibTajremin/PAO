# shellcheck shell=bash
# Static checks: formatting, linters, architecture rules and file-size limits.

# check_file_sizes enforces docs/build/01-conventions.md §1 line limits.
check_file_sizes() {
  local failed=0 file lines limit
  while IFS= read -r file; do
    lines=$(wc -l <"$file")
    case "$file" in
      *_test.go) limit=400 ;;
      *.go) limit=250 ;;
      */test/*.dart | */integration_test/*.dart) limit=300 ;;
      *.dart) limit=200 ;;
    esac
    if ((lines > limit)); then
      printf '  %s: %d lines (limit %d)\n' "${file#"$PAO_ROOT"/}" "$lines" "$limit" >&2
      failed=1
    fi
  done < <(find "$BACKEND" "$FRONTEND" \( -name '*.go' -o -name '*.dart' \) \
    -not -path '*/.dart_tool/*' -not -path '*/build/*' -not -path '*/pao_api/*' \
    -not -name '*.gen.go' -not -name '*.sql.go' -not -name '*.g.dart' \
    -not -path '*/l10n/generated/*' -not -name 'mock_*.go' 2>/dev/null)
  ((failed == 0)) || die "file-size check failed"
  ok "file sizes within limits"
}

lint_go() {
  [[ -f "$BACKEND/go.mod" ]] || return 0
  require_tool golangci-lint "https://golangci-lint.run/welcome/install/"
  require_tool go-arch-lint "go install github.com/fe3dback/go-arch-lint@v1.19.0"
  local unformatted
  unformatted=$(cd "$BACKEND" && gofmt -l .)
  [[ -z "$unformatted" ]] || die "gofmt needed: $unformatted"
  "$PAO_ROOT/scripts/gen-arch-lint.sh" "$BACKEND/.go-arch-lint.yml"
  (cd "$BACKEND" && golangci-lint run ./... && go-arch-lint check --output-color=false >/dev/null) ||
    die "Go lint failed"
  ok "Go lint and architecture rules"
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
    "$PAO_ROOT"/scripts/hooks/* || die "shellcheck failed"
  ok "shellcheck"
}

# cmd_lint runs every check, or one scope (go, dart, shell) for the per-stack CI jobs.
cmd_lint() {
  case "${1:-all}" in
    go) check_file_sizes && lint_go ;;
    dart) check_file_sizes && lint_dart ;;
    shell) lint_shell ;;
    all) check_file_sizes && lint_shell && lint_go && lint_dart ;;
    *) die "usage: pao lint [go|dart|shell|all]" ;;
  esac
}
