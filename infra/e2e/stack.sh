#!/usr/bin/env bash
# Starts a fresh stack for the end-to-end journeys and writes where it listens to
# out/e2e/.stack.env (PAO_E2E_STATE moves it). APP_ENV=test swaps in the SMS and push
# capture adapters and mounts the /__test/ hooks. PAO_E2E_PROJECT and PAO_E2E_PORT
# (default 8180; S3 on +920, worker on +1011) let several stacks run side by side.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
state=${PAO_E2E_STATE:-$root/out/e2e}
project=${PAO_E2E_PROJECT:-pao-e2e}
port=${PAO_E2E_PORT:-8180}
export PAO_E2E_API_PORT=$port PAO_E2E_S3_PORT=$((port + 920)) PAO_E2E_WORKER_PORT=$((port + 1011))
compose() {
  docker compose --project-directory "$root" -p "$project" -f "$root/infra/docker-compose.yml" \
    -f "$root/infra/e2e/compose.e2e.yml" "$@"
}
key() { head -c 32 /dev/urandom | base64; }

SEED_ADMIN_PASSWORD="e2e-$(head -c 12 /dev/urandom | base64 | tr -d '/+=')"
JWT_SIGNING_KEY=${JWT_SIGNING_KEY:-$(key)}
DATA_ENCRYPTION_KEY=${DATA_ENCRYPTION_KEY:-$(key)}
export APP_ENV=test S3_PUBLIC_ENDPOINT=http://localhost:$PAO_E2E_S3_PORT
export SEED_ADMIN_PASSWORD JWT_SIGNING_KEY DATA_ENCRYPTION_KEY

compose down -v --remove-orphans >/dev/null 2>&1 || true
mkdir -p "$state"
rm -f "$state/.admins.env"
compose up -d --build --wait
compose run --rm -T --entrypoint /app/migrate migrate seed

cat >"$state/.stack.env" <<ENV
PAO_E2E_API=http://localhost:$PAO_E2E_API_PORT
PAO_E2E_WORKER=http://localhost:$PAO_E2E_WORKER_PORT
PAO_E2E_ADMIN_PASSWORD=$SEED_ADMIN_PASSWORD
ENV
echo "e2e stack $project ready: API http://localhost:$PAO_E2E_API_PORT, worker hooks http://localhost:$PAO_E2E_WORKER_PORT"
