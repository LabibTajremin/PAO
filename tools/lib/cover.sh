# shellcheck shell=bash
# The 100% coverage gate for the backend and every Flutter package
# (docs/build/03-testing.md §2).

# cover_backend reads the merged unit + integration report of `pao test integration`
# (Backend/scripts/ci.sh test, which already failed below 100% of hand-written lines).
cover_backend() {
  [[ -f "$BACKEND/PAO.sln" ]] || return 0
  local report="$COVERAGE_DIR/backend/summary.md" lines covered total
  [[ -f "$report" ]] || test_backend_integration
  lines=$(sed -n 's/^Lines: \([0-9]*\)\/\([0-9]*\) .*/\1 \2/p' "$report")
  read -r covered total <<<"$lines"
  [[ -n "${total:-}" && "$covered" == "$total" ]] ||
    die "backend coverage below 100% (see out/coverage/backend/summary.md)"
  printf '| Backend | 100%% (%s lines) |\n' "$total" >>"$COVERAGE_DIR/summary.md"
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
  printf '| Frontend/%s | 100%% (%s lines) |\n' "${pkg#"$FRONTEND"/}" "$total" >>"$COVERAGE_DIR/summary.md"
}

cover_dart() {
  [[ -f "$FRONTEND/pubspec.yaml" ]] || return 0
  local pkg
  while IFS= read -r pkg; do cover_dart_package "$pkg"; done < <(dart_packages)
}

# cmd_cover checks every stack, or one scope (backend, dart) for the per-stack CI jobs.
cmd_cover() {
  mkdir -p "$COVERAGE_DIR"
  printf '# Coverage\n\n| Package | Lines |\n|---|---|\n' >"$COVERAGE_DIR/summary.md"
  case "${1:-all}" in
    backend) cover_backend ;;
    dart) cover_dart ;;
    all) cover_backend && cover_dart ;;
    *) die "usage: pao cover [backend|dart|all]" ;;
  esac
  ok "coverage 100% — see out/coverage/summary.md"
}
