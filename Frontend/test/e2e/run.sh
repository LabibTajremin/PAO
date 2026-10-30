#!/usr/bin/env bash
# Runs the Flutter app journeys and the start-up smoke tests against the running e2e
# stack (infra/e2e/stack.sh), failing on the first failure. The partner and customer
# apps run on the Linux desktop under a virtual display; the admin panel runs in
# Chrome through chromedriver.
#
# Usage: run.sh [partner|customer|admin ...] [-- integration_test/<file> ...]
#   (files after -- narrow the desktop apps' runs, e.g. to one journey)
#   PAO_E2E_APPS            apps to run when none are named (default: all three;
#                           "none" skips them, e.g. in the API-only CI job)
#   PAO_E2E_ADMIN_WEB_PORT  port the admin panel is served on; it must be the
#                           stack's ADMIN_CORS_ORIGIN port (default 5000)
#   CHROMEDRIVER            chromedriver matching the Chrome below (default: on PATH)
#   CHROME_EXECUTABLE       Chrome or Chromium binary (default: chromedriver's choice)
#   PAO_E2E_DRIVER_PORT     chromedriver port (default 4444)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
apps="$root/Frontend/apps"
stack_env="${PAO_E2E_STATE:-$root/out/e2e}/.stack.env"

selected=()
tests=()
while (($#)); do
  if [[ "$1" == -- ]]; then
    shift
    tests=("$@")
    break
  fi
  selected+=("$1")
  shift
done
((${#selected[@]})) || read -ra selected <<<"${PAO_E2E_APPS:-partner customer admin}"
if [[ "${selected[*]}" == none ]]; then
  echo "app journeys skipped (PAO_E2E_APPS=none)"
  exit 0
fi

[[ -f "$stack_env" ]] || {
  echo "no $stack_env: start the stack with infra/e2e/stack.sh" >&2
  exit 1
}
setting() { sed -n "s/^$1=//p" "$stack_env"; }
api=$(setting PAO_E2E_API)
defines=(
  "--dart-define=PAO_API_BASE_URL=$api"
  "--dart-define=PAO_E2E_ADMIN_PASSWORD=$(setting PAO_E2E_ADMIN_PASSWORD)"
  "--dart-define=PAO_E2E_ADMINS_FILE=${PAO_E2E_STATE:-$root/out/e2e}/.admins.env"
)

# desktop runs every file in integration_test/ (the smoke test and the journeys) on
# the Linux desktop, one `flutter test` and desktop session per file: the tool
# fails to start a second app in one run.
desktop() {
  local app="$1" file files=("${tests[@]}")
  ((${#files[@]})) || files=("$apps/$app"/integration_test/*_test.dart)
  echo "== $app (Linux desktop)"
  for file in "${files[@]}"; do
    (cd "$apps/$app" && "$here/desktop-session.sh" flutter test -d linux \
      "${defines[@]}" "$file")
  done
}

run_app() {
  case "$1" in
    partner | customer) desktop "$1" ;;
    admin) "$here/admin-web.sh" "$api" "${defines[@]}" ;;
    *)
      echo "unknown app $1 (partner, customer or admin)" >&2
      return 1
      ;;
  esac
}

for app in "${selected[@]}"; do
  start=$SECONDS
  run_app "$app"
  echo "== $app passed in $((SECONDS - start))s"
done
