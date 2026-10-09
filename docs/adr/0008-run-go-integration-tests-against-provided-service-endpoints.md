# ADR-0008: Run Go integration tests against provided service endpoints, beside the code

- Status: Accepted
- Date: 2026-10-09
- Source: docs/build/03-testing.md §1

## Context

The test plan puts Go integration tests in `test/backend/integration/` using testcontainers. Go forbids importing `backend/internal/...` from outside `backend/`, so repository tests cannot live there. Testcontainers also duplicates what CI service containers already provide.

## Decision

Integration tests live beside the code they cover in `*_integration_test.go` files with the `integration` build tag. They read `PAO_TEST_DATABASE_URL`, `PAO_TEST_REDIS_URL` and `PAO_TEST_S3_*`; `./pao test integration` starts the compose services when these are unset, and CI sets them from service containers. Each test package gets its own database cloned from a migrated template and its own Redis key prefix, so packages run in parallel safely. Shared helpers live in `backend/internal/testkit`. Black-box API journeys stay in `test/e2e/api` as planned.

## Consequences

One `go test -tags integration` run yields the merged unit + integration coverage profile. `test/backend/integration/` only documents this decision.
