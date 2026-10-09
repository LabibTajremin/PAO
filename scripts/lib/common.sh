# shellcheck shell=bash
# Shared helpers for the pao CLI: logging, failure handling and tool checks.

PAO_ROOT="${PAO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export PAO_ROOT
export BACKEND="$PAO_ROOT/backend"
export FRONTEND="$PAO_ROOT/frontend"
export COVERAGE_DIR="$PAO_ROOT/coverage"

log() { printf '\033[1;34m▸\033[0m %s\n' "$*" >&2; }
ok() { printf '\033[1;32m✔\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31m✘\033[0m %s\n' "$*" >&2
  exit 1
}

# nothing_to_run reports a command whose targets do not exist yet; it is a success.
nothing_to_run() { ok "$1: nothing to run"; }

# require_tool fails with an install hint when a binary is missing from PATH.
require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "missing tool '$1' — $2"
}

# retry runs a command up to five times with exponential backoff (2s, 4s, 8s, 16s);
# used for network operations such as git push.
retry() {
  local delay=2 attempt
  for attempt in 1 2 3 4 5; do
    if "$@"; then return 0; fi
    [[ $attempt -eq 5 ]] && break
    log "attempt $attempt failed; retrying in ${delay}s"
    sleep "$delay"
    delay=$((delay * 2))
  done
  return 1
}

# dart_packages lists every Flutter package directory in the workspace.
dart_packages() {
  local dir
  for dir in "$FRONTEND"/apps/* "$FRONTEND"/packages/*; do
    [[ -f "$dir/pubspec.yaml" ]] && printf '%s\n' "$dir"
  done
  return 0
}
