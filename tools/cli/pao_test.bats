#!/usr/bin/env bats
# Argument handling and exit codes of the pao CLI and the commit-msg hook.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  PAO="$ROOT/pao"
}

@test "no command prints usage and exits 2" {
  run "$PAO"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: pao <command>"* ]]
}

@test "help exits 0" {
  run "$PAO" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase finish <id>"* ]]
}

@test "unknown command exits 2" {
  run "$PAO" fly
  [ "$status" -eq 2 ]
}

@test "test without a level fails with usage" {
  run "$PAO" test
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao test unit|integration|e2e|all (or backend|dart)"* ]]
}

@test "lint, cover with an unknown scope fail with usage" {
  run "$PAO" lint go
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao lint [backend|dart|shell|sizes|motion|all]"* ]]
  run "$PAO" cover go
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao cover [backend|dart|all]"* ]]
}

@test "file-size limits: Dart 200, Dart tests 300, C# left to the backend gate" {
  run bash -c ". '$ROOT/tools/lib/lint.sh'; size_limit a/lib/b.dart; size_limit a/test/b_test.dart;
    size_limit a/integration_test/c_test.dart; size_limit Backend/A.cs"
  [ "$status" -eq 0 ]
  [ "$output" == "$(printf '200\n300\n300')" ]
}

@test "motion timing: raw milliseconds and curves fail, seconds and tokens pass" {
  local fe="$BATS_TEST_TMPDIR/Frontend" lib
  lib="$fe/apps/x/lib/features/y"
  mkdir -p "$lib" "$fe/packages/pao_ui/lib/src/widgets"
  printf 'const a = PaoMotion.base;\nconst t = Duration(seconds: 1);\n' >"$lib/ok.dart"
  run bash -c ". '$ROOT/tools/lib/common.sh'; . '$ROOT/tools/lib/lint.sh'; FRONTEND='$fe' check_motion"
  [ "$status" -eq 0 ]
  printf 'const d = Duration(milliseconds: 250);\n' >"$lib/bad.dart"
  run bash -c ". '$ROOT/tools/lib/common.sh'; . '$ROOT/tools/lib/lint.sh'; FRONTEND='$fe' check_motion"
  [ "$status" -ne 0 ]
  [[ "$output" == *"bad.dart:1"* ]]
}

@test "the root wrapper runs tools/pao" {
  run "$PAO" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Backend/scripts/ci.sh"* ]]
}

@test "phase without finish <id> fails with usage" {
  run "$PAO" phase start P01
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao phase finish <id>"* ]]
}

@test "ops without a known action fails with usage" {
  run "$PAO" ops backup
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao ops check|restore-test [e2e]"* ]]
}

@test "perf with no load project has nothing to run" {
  PAO_ROOT="$BATS_TEST_TMPDIR" run bash -c ". '$ROOT/tools/lib/common.sh'; nothing_to_run perf"
  [ "$status" -eq 0 ]
  [[ "$output" == *"perf: nothing to run"* ]]
}

@test "retry gives up after five attempts" {
  run bash -c ". '$ROOT/tools/lib/common.sh'; sleep() { :; }; retry false"
  [ "$status" -eq 1 ]
  [[ "$output" == *"attempt 4 failed"* ]]
}

@test "commit-msg accepts a Conventional Commit" {
  echo "feat(booking): add start-code verification" >"$BATS_TEST_TMPDIR/msg"
  run "$ROOT/tools/hooks/commit-msg" "$BATS_TEST_TMPDIR/msg"
  [ "$status" -eq 0 ]
}

@test "commit-msg rejects a free-form subject" {
  echo "fixed stuff" >"$BATS_TEST_TMPDIR/msg"
  run "$ROOT/tools/hooks/commit-msg" "$BATS_TEST_TMPDIR/msg"
  [ "$status" -eq 1 ]
}

@test "commit-msg rejects a subject over 72 characters" {
  printf 'docs: %070d\n' 0 >"$BATS_TEST_TMPDIR/msg"
  run "$ROOT/tools/hooks/commit-msg" "$BATS_TEST_TMPDIR/msg"
  [ "$status" -eq 1 ]
}

@test "release files name the app, flavour and version" {
  source "$ROOT/tools/lib/release_name.sh"
  pubspec="$BATS_TEST_TMPDIR/pubspec.yaml"
  printf 'name: x\nversion: 1.2.0+7\n' >"$pubspec"
  [ "$(release_version "$pubspec")" = "1.2.0-7" ]
  [ "$(release_version "$pubspec" 45)" = "1.2.0-45" ]
  [ "$(release_name partner prod 1.2.0-45 apk)" = "pao-partner-prod-1.2.0-45.apk" ]
  [ "$(release_name customer dev 1.2.0-7 aab)" = "pao-customer-dev-1.2.0-7.aab" ]
}

@test "a version without a build number counts as build 0" {
  source "$ROOT/tools/lib/release_name.sh"
  pubspec="$BATS_TEST_TMPDIR/pubspec.yaml"
  printf 'version: 2.0.1\n' >"$pubspec"
  [ "$(release_version "$pubspec")" = "2.0.1-0" ]
}

@test "the mobile apps' release builds never keep Flutter's app-release name" {
  run grep -n 'app-release\|\*-release\.apk' "$ROOT/.github/workflows/frontend.yml"
  [ "$status" -eq 1 ]
}
