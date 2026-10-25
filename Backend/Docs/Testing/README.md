# Testing and gates

| Project | Runs against | Covers |
|---|---|---|
| `Test/PAO.UnitTests` | in-memory fakes, `FakeClock` | rules, edge, crypto (with vectors from earlier releases), architecture, size and docs gates |
| `Test/PAO.IntegrationTests` | Postgres, Redis and S3 from the environment (ADR-0008) | migrator, Redis helpers, RBAC, outbox, scheduler, storage, the full API through TestServer |
| `Test/PAO.E2ETests` | built hosts as processes; the e2e Docker stack (`Journeys/`) | start-up smoke of api, worker, migrator; the black-box API journeys (`Category=Journey`) |
| `Test/PAO.LoadTests` | the e2e Docker stack | C# load test (console app): nearby search p95 < 300 ms, no failures |
| `Test/PAO.TestKit` | — | `TestEnvironment` (`PAO_TEST_*`), private databases from a migrated template, fakes |

Each integration test class gets a private database (`pao_net_test_*`) and its own Redis
key environment; nothing shared is dropped.

## Gates (`./pao dotnet ci`, `Backend/scripts/ci.sh`)

1. `dotnet build` with warnings as errors (analyzers, CS1591 XML docs).
2. `dotnet format --verify-no-changes`.
3. Gate tests: architecture rules (NetArchTest), authorisation attributes, size limits,
   docs coverage.
4. Unit and integration tests with Microsoft code coverage, merged by
   `scripts/coverage.py`, gated at 100% line coverage. Only generated code and the three
   `Program.cs` files are excluded (`coverage.config`).
5. The bundled spec is current (`scripts/gen-spec.sh --check`; the contract folder is the MSBuild property `PaoApiDir`).
6. E2E start-up smoke tests (the journeys are filtered out by their trait; `./pao test e2e`
   runs them against a fresh stack).

## Black-box journeys and load

`infra/docker-compose.yml` builds the api, worker and migrate services from
`Backend/docker/Dockerfile`, so `infra/e2e/stack.sh` and every journey run against
the .NET hosts: the API journeys (`Test/PAO.E2ETests/Journeys`, plain HTTP, no backend
references), the app journeys
(`Frontend/test/e2e/run.sh`: partner, customer and admin) and the load-test thresholds
(`./pao perf e2e`). With `APP_ENV=test` the hosts mount the hooks in
`PAO.Infrastructure/Testing/TestHooks.cs` (`/__test/sms`, `/__test/pushes`,
`/__test/verification/expire`); `migrate seed` and `migrate perf-seed N` prepare the data.
`./pao test e2e` runs the smoke tests and journeys, `./pao perf e2e` the load tests
(`Test/PAO.LoadTests`); `./pao ci` runs both. The commission is charged from
the booking-completed event, so journeys wait for the due to appear rather than reading it
straight after completion.
