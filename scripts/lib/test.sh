# shellcheck shell=bash
# Test runners for every level in docs/build/03-testing.md §1.

test_backend_unit() {
  [[ -f "$BACKEND/package.json" ]] || return 0
  npm_install "$BACKEND"
  (cd "$BACKEND" && npx jest --selectProjects unit --silent) || die "backend unit tests failed"
  ok "backend unit tests"
}

test_cli() {
  require_tool bats "apt install bats"
  bats "$PAO_ROOT/test/cli" >/dev/null || die "CLI tests failed (run: bats test/cli)"
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

# test_backend_integration runs the unit and integration projects together so the
# report measures the combined coverage the 100% gate (pao cover) applies to.
test_backend_integration() {
  [[ -f "$BACKEND/package.json" ]] || {
    nothing_to_run "backend integration"
    return 0
  }
  ensure_test_services
  npm_install "$BACKEND"
  rm -rf "$COVERAGE_DIR/backend"
  mkdir -p "$COVERAGE_DIR"
  (cd "$BACKEND" && npx jest --runInBand --silent --coverage --coverageThreshold '{}' \
    --coverageReporters json-summary text-summary --coverageDirectory "$COVERAGE_DIR/backend") \
    >"$COVERAGE_DIR/backend.txt" 2>&1 || {
    tail -60 "$COVERAGE_DIR/backend.txt" >&2
    die "backend unit + integration tests failed"
  }
  ok "backend unit + integration tests"
}

test_e2e() {
  local ran=0
  if [[ -d "$E2E_API" ]]; then
    "$PAO_ROOT/test/e2e/stack.sh" || die "e2e stack failed"
    dotnet test --project "$E2E_API" -- --filter-trait "Category=Journey" || die "API e2e journeys failed"
    ran=1
  fi
  if [[ -x "$PAO_ROOT/test/e2e/mobile/run.sh" ]]; then
    "$PAO_ROOT/test/e2e/mobile/run.sh" || die "app journeys failed"
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
    all) test_cli && test_backend_unit && test_dart && test_backend_integration && test_e2e ;;
    *) die "usage: pao test unit|integration|e2e|all (or backend|dart)" ;;
  esac
}
