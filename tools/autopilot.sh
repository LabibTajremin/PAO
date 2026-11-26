#!/usr/bin/env bash
# Runs the automatic agentic run until every phase is done, sleeping through usage limits.
# Start it in tmux on a dedicated machine after the preflight is done:  tools/autopilot.sh
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
STATE=docs/build/PROGRESS.md
LIMIT_WAIT=${LIMIT_WAIT:-900}; MAX_RUNS=${MAX_RUNS:-300}
mkdir -p .autopilot; LOG=.autopilot/autopilot.log
PROMPT='automatic agentic run. Never ask questions.'
log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }
for ((run = 1; run <= MAX_RUNS; run++)); do
  git pull --ff-only -q 2>/dev/null || true
  case "$(head -n1 "$STATE" 2>/dev/null)" in
    ALL_PHASES_DONE*) log "All phases done."; exit 0 ;;
    BLOCKED*) log "Stopped: $(head -n1 "$STATE")"; exit 1 ;;
  esac
  out=$(claude -p "$PROMPT" --dangerously-skip-permissions 2>&1); code=$?
  printf '%s\n' "$out" | tail -n 40 >> "$LOG"
  if printf '%s' "$out" | grep -qiE 'usage limit|limit reached|rate.?limit|resets? at|overloaded|529'; then
    log "usage limit — sleeping ${LIMIT_WAIT}s"; sleep "$LIMIT_WAIT"
  elif (( code != 0 )); then log "exit $code — retry in 60s"; sleep 60; fi
done
log "MAX_RUNS reached"; exit 2
