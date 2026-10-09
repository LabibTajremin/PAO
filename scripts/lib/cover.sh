# shellcheck shell=bash
# The 100% coverage gate for Go and every Flutter package (docs/build/03-testing.md §2).

cover_go() {
  [[ -f "$BACKEND/go.mod" ]] || return 0
  require_tool go-test-coverage "go install github.com/vladopajic/go-test-coverage/v2@v2.11.4"
  [[ -f "$COVERAGE_DIR/go.out" ]] || test_go_integration
  local config="$COVERAGE_DIR/testcoverage.yml"
  {
    cat "$PAO_ROOT/.testcoverage.yml"
    printf 'exclude:\n  paths:\n'
    grep -v -e '^#' -e '^$' "$PAO_ROOT/.coverage-exclude" | sed "s/^/    - '/; s/\$/'/"
  } >"$config"
  (cd "$BACKEND" && go-test-coverage --config "$config" \
    --profile "$COVERAGE_DIR/go.out") >"$COVERAGE_DIR/go.txt" 2>&1 || {
    grep -v '100.0%' "$COVERAGE_DIR/go.txt" | tail -40 >&2
    die "Go coverage below 100%"
  }
  printf '| Go backend | 100%% |\n' >>"$COVERAGE_DIR/summary.md"
}

# dart_excludes prints the regexes listed under coverage_exclude in a pubspec.
dart_excludes() {
  awk '/^coverage_exclude:/{on=1;next} on&&/^  - /{sub(/^  - /,"");gsub(/["\047]/,"");print;next} on&&!/^  /{on=0}' "$1"
}

cover_dart_package() {
  local pkg="$1" lcov="$1/coverage/lcov.info" pattern result
  [[ -d "$pkg/test" ]] || return 0
  [[ -f "$lcov" ]] || die "no coverage for ${pkg#"$PAO_ROOT"/}; run ./pao test unit"
  pattern=$(dart_excludes "$pkg/pubspec.yaml" | paste -sd'|' -)
  result=$(awk -v ex="${pattern:-^$}" '
    /^SF:/ { file=substr($0,4); skip=(file ~ ex) }
    /^DA:/ && !skip { split(substr($0,4),a,","); total++; if (a[2]>0) hit++; else miss[file]=miss[file] " " a[1] }
    END { for (f in miss) print "  " f ":" miss[f] > "/dev/stderr"; printf "%d %d", hit, total }' "$lcov")
  read -r hit total <<<"$result"
  [[ "$hit" == "$total" ]] || die "coverage ${hit}/${total} in ${pkg#"$PAO_ROOT"/}"
  printf '| %s | 100%% (%s lines) |\n' "${pkg#"$FRONTEND"/}" "$total" >>"$COVERAGE_DIR/summary.md"
}

cover_dart() {
  [[ -f "$FRONTEND/pubspec.yaml" ]] || return 0
  local pkg
  while IFS= read -r pkg; do cover_dart_package "$pkg"; done < <(dart_packages)
}

# cmd_cover checks every stack, or one scope (go, dart) for the per-stack CI jobs.
cmd_cover() {
  mkdir -p "$COVERAGE_DIR"
  printf '# Coverage\n\n| Package | Statements |\n|---|---|\n' >"$COVERAGE_DIR/summary.md"
  case "${1:-all}" in
    go) cover_go ;;
    dart) cover_dart ;;
    all) cover_go && cover_dart ;;
    *) die "usage: pao cover [go|dart|all]" ;;
  esac
  ok "coverage 100% — see coverage/summary.md"
}
