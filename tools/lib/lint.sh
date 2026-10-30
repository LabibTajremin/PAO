# shellcheck shell=bash
# Static checks: formatting, analyzers, architecture rules and file-size limits.

# size_limit prints the Dart line limit of docs/build/01-conventions.md §1 for a file.
# C# limits are enforced by the backend's size gate (Backend/Tools/PAO.Gates).
size_limit() {
  case "$1" in
    */test/*.dart | */integration_test/*.dart) echo 300 ;;
    *.dart) echo 200 ;;
  esac
}

# hand_written lists the Dart sources the size limits apply to; generated code is left out.
hand_written() {
  find "$FRONTEND" -name '*.dart' \
    -not -path '*/coverage/*' -not -name '*.gen.*' \
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

# lint_backend builds the .NET solution with warnings as errors, checks its formatting and
# runs the architecture, authorisation, size and docs gates (journeys included).
lint_backend() {
  [[ -f "$BACKEND/PAO.sln" ]] || return 0
  backend_ci format || die "backend format check failed"
  backend_ci gates || die "backend gates failed"
  ok "backend build, format, architecture, size and docs gates"
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
  shellcheck "$PAO_ROOT/pao" "$PAO_ROOT/tools/pao" "$PAO_ROOT"/tools/*.sh "$PAO_ROOT"/tools/lib/*.sh \
    "$PAO_ROOT"/tools/hooks/* "$INFRA"/e2e/*.sh "$APP_JOURNEYS"/*.sh \
    "$BACKEND"/scripts/*.sh || die "shellcheck failed"
  ok "shellcheck"
}

# cmd_lint runs every check, or one scope for the CI jobs and the pre-commit hook.
cmd_lint() {
  case "${1:-all}" in
    backend) lint_backend ;;
    dart) check_file_sizes && lint_dart ;;
    shell) lint_shell ;;
    sizes) check_file_sizes ;;
    all) check_file_sizes && lint_shell && lint_backend && lint_dart ;;
    *) die "usage: pao lint [backend|dart|shell|sizes|all]" ;;
  esac
}
