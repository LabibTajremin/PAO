#!/usr/bin/env bash
# Runs the admin panel's start-up smoke test and journey in Chrome through
# chromedriver (flutter drive). Called by run.sh: admin-web.sh <api url> <dart-defines…>
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
admin="$root/frontend/apps/admin"
api="$1"
shift
defines=("$@")
web_port=${PAO_E2E_ADMIN_WEB_PORT:-5000}
driver_port=${PAO_E2E_DRIVER_PORT:-4444}

# The API answers the browser only from the one origin it allows.
origin="http://localhost:$web_port"
if ! curl -sS -o /dev/null -D - -X OPTIONS -H "Origin: $origin" \
  -H 'Access-Control-Request-Method: POST' "$api/v1/auth/admin/login" |
  grep -qi "^access-control-allow-origin: $origin"; then
  echo "the stack does not allow $origin: start it with ADMIN_CORS_ORIGIN=$origin" \
    "or set PAO_E2E_ADMIN_WEB_PORT to its port" >&2
  exit 1
fi

"${CHROMEDRIVER:-chromedriver}" --port="$driver_port" >/dev/null 2>&1 &
driver=$!
trap 'kill "$driver" 2>/dev/null || true' EXIT
for _ in $(seq 50); do
  curl -sf "http://localhost:$driver_port/status" >/dev/null && break
  sleep 0.2
done

# A provider waiting for review and the verifier's authenticator key: the browser
# can neither read the SMS capture nor keep the key for later journeys.
prepared=$(cd "$root/frontend" &&
  dart run pao_e2e:submitted_provider "$root/test/e2e/.stack.env")
while IFS= read -r line; do
  defines+=("--dart-define=$line")
done < <(grep '^PAO_E2E_' <<<"$prepared")

chrome=()
if [[ -n "${CHROME_EXECUTABLE:-}" ]]; then chrome=("--chrome-binary=$CHROME_EXECUTABLE"); fi
for target in integration_test/smoke_test.dart integration_test/admin_journey_test.dart; do
  echo "== admin $target (Chrome)"
  (cd "$admin" && flutter drive -d web-server --browser-name=chrome "${chrome[@]}" \
    --driver=test_driver/integration_test.dart --target="$target" \
    --driver-port="$driver_port" --web-port="$web_port" "${defines[@]}")
done
