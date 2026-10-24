# shellcheck shell=bash
# Operations checks: alert rules and dashboards (infra/ops/), and the backup restore drill
# (docs/runbooks/restore-database.md).

PROMTOOL_IMAGE="quay.io/prometheus/prometheus:v3.5.0"
RESTORE_DB="pao_restore_drill"

cmd_ops() {
  case "${1:-}" in
    check) ops_check ;;
    restore-test) ops_restore_test "${2:-}" ;;
    *) die "usage: pao ops check|restore-test [e2e]" ;;
  esac
}

# run_promtool runs the local promtool, or the pinned Prometheus image's copy.
run_promtool() {
  if type -P promtool >/dev/null; then
    promtool "$@"
    return
  fi
  require_tool docker "https://prometheus.io/download/ (promtool) or Docker"
  docker run --rm --quiet -v "$INFRA/ops:/ops:ro" -w / --entrypoint promtool "$PROMTOOL_IMAGE" \
    "${@//"$INFRA"\//}"
}

# ops_check validates the Prometheus rules, runs their unit tests and checks that every
# dashboard is JSON whose queries only use metrics the backend exports.
ops_check() {
  require_tool jq "https://jqlang.org/download/"
  run_promtool check config "$INFRA/ops/prometheus/prometheus.yml" >/dev/null ||
    die "invalid Prometheus configuration or rules"
  run_promtool test rules "$INFRA"/ops/prometheus/tests/*.yml >/dev/null ||
    die "Prometheus rule tests failed"
  local board metric known
  known=$(grep -rhoE '"pao_[a-z_]+"' "$BACKEND/PAO.Infrastructure/Metrics" | tr -d '"')
  for board in "$INFRA"/ops/grafana/dashboards/*.json; do
    jq -e '.title and .uid and (.panels | length > 0)' "$board" >/dev/null ||
      die "${board#"$PAO_ROOT"/} is not a dashboard"
    while IFS= read -r metric; do
      grep -qx "${metric%_bucket}" <<<"$known" || grep -qx "${metric%_count}" <<<"$known" ||
        grep -qx "${metric%_sum}" <<<"$known" ||
        die "${board#"$PAO_ROOT"/} queries $metric, which the backend does not export"
    done < <(jq -r '.. | .expr? // empty' "$board" | grep -oE 'pao_[a-z_]+' | sort -u)
  done
  ok "alert rules and dashboards valid"
}

# ops_restore_test dumps the stack's database, restores the dump into a scratch
# database on the same server and compares row counts and migration versions. The
# source is read inside an exported snapshot, so a running worker cannot skew the counts.
ops_restore_test() {
  local db=(compose) dump snapshot source restored
  [[ "$1" == e2e ]] && db=(e2e_compose)
  require_tool docker "https://docs.docker.com/engine/install/"
  dump=$(mktemp)
  trap 'rm -f "$dump"; trap - RETURN' RETURN
  coproc SNAP { "${db[@]}" exec -T postgres psql -U pao -d pao -AtqX -v ON_ERROR_STOP=1; }
  printf 'BEGIN ISOLATION LEVEL REPEATABLE READ;\nSELECT pg_export_snapshot();\n' >&"${SNAP[1]}"
  read -r snapshot <&"${SNAP[0]}" || die "is the stack up? (./pao up && ./pao seed)"
  "${db[@]}" exec -T postgres pg_dump -U pao -d pao -Fc --snapshot="$snapshot" >"$dump" ||
    die "pg_dump failed"
  source=$(snapshot_fingerprint)
  printf 'COMMIT;\n\\q\n' >&"${SNAP[1]}"
  wait "$SNAP_PID" 2>/dev/null || true
  grep -q '^migration ' <<<"$source" || die "the source database has no migrations; run ./pao seed"
  "${db[@]}" exec -T postgres psql -U pao -d postgres -qX -v ON_ERROR_STOP=1 \
    -c "SET client_min_messages = warning" -c "DROP DATABASE IF EXISTS $RESTORE_DB" -c "CREATE DATABASE $RESTORE_DB TEMPLATE template0" ||
    die "could not create the scratch database"
  "${db[@]}" exec -T postgres pg_restore -U pao -d "$RESTORE_DB" --no-owner --exit-on-error <"$dump" ||
    die "pg_restore failed"
  restored=$("${db[@]}" exec -T postgres psql -U pao -d "$RESTORE_DB" -AtqX -v ON_ERROR_STOP=1 \
    <"$PAO_ROOT/tools/ops/fingerprint.sql") || die "could not read the restored database"
  "${db[@]}" exec -T postgres psql -U pao -d postgres -qX -c "DROP DATABASE $RESTORE_DB" >/dev/null
  if [[ "$source" != "$restored" ]]; then
    diff <(printf '%s\n' "$source") <(printf '%s\n' "$restored") >&2
    die "the restored database differs from its source"
  fi
  ok "restore drill passed: $(grep -c . <<<"$source") tables and versions match ($(du -h "$dump" | cut -f1) dump)"
}

# snapshot_fingerprint runs fingerprint.sql in the coprocess's snapshot transaction.
snapshot_fingerprint() {
  local line
  {
    cat "$PAO_ROOT/tools/ops/fingerprint.sql"
    printf "SELECT '__end__';\n"
  } >&"${SNAP[1]}"
  while read -r line <&"${SNAP[0]}" && [[ "$line" != __end__ ]]; do
    printf '%s\n' "$line"
  done
}
