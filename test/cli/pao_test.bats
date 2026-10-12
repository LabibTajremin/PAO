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
  [[ "$output" == *"usage: pao lint [backend|dart|shell|sizes|all]"* ]]
  run "$PAO" cover go
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao cover [backend|dart|all]"* ]]
}

@test "file-size limits: specs 400, TypeScript 250, Dart 200, Dart tests 300" {
  run bash -c ". '$ROOT/scripts/lib/lint.sh'; size_limit a/b.spec.ts; size_limit a/b.int-spec.ts;
    size_limit a/b.ts; size_limit a/lib/b.dart; size_limit a/test/b_test.dart"
  [ "$status" -eq 0 ]
  [ "$output" == "$(printf '400\n400\n250\n200\n300')" ]
}

@test "phase without finish <id> fails with usage" {
  run "$PAO" phase start P01
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: pao phase finish <id>"* ]]
}

@test "perf with no scripts has nothing to run" {
  PAO_ROOT="$BATS_TEST_TMPDIR" run bash -c ". '$ROOT/scripts/lib/common.sh'; nothing_to_run perf"
  [ "$status" -eq 0 ]
  [[ "$output" == *"perf: nothing to run"* ]]
}

@test "retry gives up after five attempts" {
  run bash -c ". '$ROOT/scripts/lib/common.sh'; sleep() { :; }; retry false"
  [ "$status" -eq 1 ]
  [[ "$output" == *"attempt 4 failed"* ]]
}

@test "commit-msg accepts a Conventional Commit" {
  echo "feat(booking): add start-code verification" >"$BATS_TEST_TMPDIR/msg"
  run "$ROOT/scripts/hooks/commit-msg" "$BATS_TEST_TMPDIR/msg"
  [ "$status" -eq 0 ]
}

@test "commit-msg rejects a free-form subject" {
  echo "fixed stuff" >"$BATS_TEST_TMPDIR/msg"
  run "$ROOT/scripts/hooks/commit-msg" "$BATS_TEST_TMPDIR/msg"
  [ "$status" -eq 1 ]
}

@test "commit-msg rejects a subject over 72 characters" {
  printf 'docs: %070d\n' 0 >"$BATS_TEST_TMPDIR/msg"
  run "$ROOT/scripts/hooks/commit-msg" "$BATS_TEST_TMPDIR/msg"
  [ "$status" -eq 1 ]
}
