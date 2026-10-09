# shellcheck shell=bash
# Test runners for every level in docs/build/03-testing.md §1.

test_go_unit() {
  [[ -f "$BACKEND/go.mod" ]] || return 0
  (cd "$BACKEND" && go test -race -count=1 ./...) || die "Go unit tests failed"
  ok "Go unit tests"
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
    (cd "$pkg" && flutter test --coverage --no-pub >/dev/null) || die "Flutter tests failed in ${pkg#"$PAO_ROOT"/}"
  done < <(dart_packages)
  ok "Flutter unit and widget tests"
}

# test_go_integration runs unit and integration-tagged tests together so the profile
# measures the combined coverage the 100% gate applies to.
test_go_integration() {
  [[ -f "$BACKEND/go.mod" ]] || {
    nothing_to_run "Go integration"
    return 0
  }
  ensure_test_services
  mkdir -p "$COVERAGE_DIR"
  (cd "$BACKEND" && go test -tags integration -race -count=1 -covermode=atomic \
    -coverpkg=./internal/... -coverprofile="$COVERAGE_DIR/go.out" ./...) ||
    die "Go integration tests failed"
  ok "Go unit + integration tests"
}

test_e2e() {
  local ran=0
  if [[ -f "$PAO_ROOT/test/e2e/go.mod" ]]; then
    "$PAO_ROOT/test/e2e/stack.sh" || die "e2e stack failed"
    (cd "$PAO_ROOT/test/e2e" && go test -count=1 ./...) || die "API e2e journeys failed"
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
    unit) test_cli && test_go_unit && test_dart ;;
    go) test_go_unit ;;
    dart) test_dart ;;
    integration) test_go_integration ;;
    e2e) test_e2e ;;
    all) test_cli && test_go_unit && test_dart && test_go_integration && test_e2e ;;
    *) die "usage: pao test unit|integration|e2e|all (or go|dart)" ;;
  esac
}
