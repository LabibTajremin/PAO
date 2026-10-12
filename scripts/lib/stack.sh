# shellcheck shell=bash
# Docker stack lifecycle and the database/Redis/S3 endpoints used by tests.

compose() { docker compose -f "$PAO_ROOT/docker-compose.yml" "$@"; }

# e2e_compose addresses the end-to-end stack that test/e2e/stack.sh started.
e2e_compose() {
  docker compose -p "${PAO_E2E_PROJECT:-pao-e2e}" -f "$PAO_ROOT/docker-compose.yml" \
    -f "$PAO_ROOT/test/e2e/compose.e2e.yml" "$@"
}

cmd_up() {
  require_tool docker "https://docs.docker.com/engine/install/"
  [[ -f "$PAO_ROOT/.env" ]] || create_env
  compose up -d --build --wait || die "stack failed to become healthy"
  ok "stack healthy — API on http://localhost:8080"
}

cmd_down() {
  require_tool docker "https://docs.docker.com/engine/install/"
  compose down --remove-orphans
  ok "stack stopped"
}

# ensure_test_services exports the PAO_TEST_* endpoints. CI provides them through
# service containers; locally the compose infrastructure services are started.
ensure_test_services() {
  if [[ -z "${PAO_TEST_DATABASE_URL:-}" ]]; then
    require_tool docker "https://docs.docker.com/engine/install/"
    compose up -d --wait postgres redis minio >/dev/null || die "test services failed to start"
    export PAO_TEST_DATABASE_URL="postgres://pao:pao@localhost:5432/pao?sslmode=disable"
    export PAO_TEST_REDIS_URL="redis://localhost:6379/15"
    export PAO_TEST_S3_ENDPOINT="http://localhost:9000"
    export PAO_TEST_S3_ACCESS_KEY="${S3_ACCESS_KEY:-pao-local}"
    export PAO_TEST_S3_SECRET_KEY="${S3_SECRET_KEY:-change-me-local-only}"
  fi
}

# cmd_seed applies the migrations and loads the seed data through the image's migrate
# entry point, using the same settings as the running stack.
cmd_seed() {
  require_tool docker "https://docs.docker.com/engine/install/"
  [[ -f "$PAO_ROOT/.env" ]] || create_env
  compose run --rm -T --entrypoint /app/migrate migrate up >/dev/null || die "migrations failed"
  compose run --rm -T --entrypoint /app/migrate migrate seed || die "seed failed"
  ok "migrations applied and seed data loaded"
}
