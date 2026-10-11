#!/usr/bin/env bash
# Starts a fresh stack for the end-to-end journeys and writes where it listens to
# test/e2e/.stack.env. APP_ENV=test swaps in the SMS and push capture adapters and
# mounts the /__test/ hooks (API on :8180, worker pushes on :9191).
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
compose() { docker compose -f "$root/docker-compose.yml" -f "$root/test/e2e/compose.e2e.yml" "$@"; }
key() { head -c 32 /dev/urandom | base64; }

export APP_ENV=test
export S3_PUBLIC_ENDPOINT=http://localhost:9100
export SEED_ADMIN_PASSWORD="e2e-$(head -c 12 /dev/urandom | base64 | tr -d '/+=')"
export JWT_SIGNING_KEY=${JWT_SIGNING_KEY:-$(key)}
export DATA_ENCRYPTION_KEY=${DATA_ENCRYPTION_KEY:-$(key)}

compose down -v --remove-orphans >/dev/null 2>&1 || true
rm -f "$root/test/e2e/.admins.env"
compose up -d --build --wait
compose run --rm -T --entrypoint /app/migrate migrate seed

cat >"$root/test/e2e/.stack.env" <<ENV
PAO_E2E_API=http://localhost:8180
PAO_E2E_WORKER=http://localhost:9191
PAO_E2E_ADMIN_PASSWORD=$SEED_ADMIN_PASSWORD
ENV
echo "e2e stack ready: API http://localhost:8180, worker hooks http://localhost:9191"
