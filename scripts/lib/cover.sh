# shellcheck shell=bash
# The 100% coverage gate for the backend and every Flutter package
# (docs/build/03-testing.md §2).

# cover_backend checks the combined unit + integration report of `pao test integration`
# against the gate in backend/jest.config.ts: statements, lines and functions at 100%.
cover_backend() {
  [[ -f "$BACKEND/package.json" ]] || return 0
  local report="$COVERAGE_DIR/backend/coverage-summary.json"
  [[ -f "$report" ]] || test_backend_integration
  # shellcheck disable=SC2016 # the ${...} below are JavaScript template literals
  node -e '
    const total = require(process.argv[1]).total;
    const short = ["statements", "lines", "functions"].filter((k) => total[k].pct < 100);
    for (const k of short) console.error(`  ${k}: ${total[k].covered}/${total[k].total}`);
    console.log(total.statements.total);
    process.exit(short.length ? 1 : 0);
  ' "$report" >"$COVERAGE_DIR/backend.count" || die "backend coverage below 100% (see coverage/backend/)"
  printf '| backend | 100%% (%s statements) |\n' "$(cat "$COVERAGE_DIR/backend.count")" >>"$COVERAGE_DIR/summary.md"
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

# cmd_cover checks every stack, or one scope (backend, dart) for the per-stack CI jobs.
cmd_cover() {
  mkdir -p "$COVERAGE_DIR"
  printf '# Coverage\n\n| Package | Statements |\n|---|---|\n' >"$COVERAGE_DIR/summary.md"
  case "${1:-all}" in
    backend) cover_backend ;;
    dart) cover_dart ;;
    all) cover_backend && cover_dart ;;
    *) die "usage: pao cover [backend|dart|all]" ;;
  esac
  ok "coverage 100% — see coverage/summary.md"
}
