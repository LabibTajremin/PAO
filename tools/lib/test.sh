# shellcheck shell=bash
# Test runners for every level in docs/build/03-testing.md §1.

test_backend_unit() {
  [[ -f "$BACKEND/PAO.sln" ]] || return 0
  backend_ci unit || die "backend unit tests failed"
  ok "backend unit tests"
}

test_cli() {
  require_tool bats "apt install bats"
  bats "$PAO_ROOT/tools/cli" >/dev/null || die "CLI tests failed (run: bats tools/cli)"
  ok "CLI tests"
}

test_dart() {
  [[ -f "$FRONTEND/pubspec.yaml" ]] || return 0
  require_tool flutter "https://docs.flutter.dev/get-started/install"
  local pkg
  while IFS= read -r pkg; do
    [[ -d "$pkg/test" ]] || continue
    local log
    log="$(mktemp)"
    # Output stays quiet on success, but a failure must name its test or it cannot be fixed.
    if ! (cd "$pkg" && flutter test --coverage --no-pub >"$log" 2>&1); then
      grep -E -B2 -A30 'EXCEPTION CAUGHT|\[E\]$|Test failed' "$log" | tail -n 120 >&2
      rm -f "$log"
      die "Flutter tests failed in ${pkg#"$PAO_ROOT"/}"
    fi
    rm -f "$log"
  done < <(dart_packages)
  ok "Flutter unit and widget tests"
}

# test_backend_integration runs the unit and integration projects with merged coverage,
# the report the 100% gate (pao cover) applies to.
test_backend_integration() {
  [[ -f "$BACKEND/PAO.sln" ]] || {
    nothing_to_run "backend integration"
    return 0
  }
  ensure_test_services
  backend_ci test || die "backend unit + integration tests (or their coverage) failed"
  ok "backend unit + integration tests"
}

# test_e2e runs the hosts' start-up smoke tests, then the black-box API journeys and the
# app journeys against a fresh e2e stack.
test_e2e() {
  local ran=0
  if [[ -d "$E2E_TESTS" ]]; then
    ensure_test_services
    backend_ci e2e || die "start-up smoke tests failed"
    "$E2E_STACK" || die "e2e stack failed"
    (cd "$BACKEND" && PAO_E2E_STATE="$E2E_STATE" dotnet test --project Test/PAO.E2ETests --no-build -- \
      --filter-trait "Category=Journey") || die "API e2e journeys failed"
    ran=1
  fi
  if [[ -x "$APP_JOURNEYS/run.sh" ]]; then
    "$APP_JOURNEYS/run.sh" || die "app journeys failed"
    ran=1
  fi
  if ((ran == 1)); then ok "end-to-end journeys"; else nothing_to_run "e2e"; fi
}

cmd_test() {
  case "${1:-}" in
    unit) test_cli && test_backend_unit && test_dart ;;
    backend) test_backend_unit ;;
    dart) test_dart ;;
    integration) test_backend_integration ;;
    e2e) test_e2e ;;
    all) test_cli && test_dart && test_backend_integration && test_e2e ;;
    *) die "usage: pao test unit|integration|e2e|all (or backend|dart)" ;;
  esac
}
