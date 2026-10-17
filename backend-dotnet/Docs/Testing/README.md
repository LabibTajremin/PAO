# Testing and gates

| Project | Runs against | Covers |
|---|---|---|
| `Test/PAO.UnitTests` | in-memory fakes, `FakeClock` | rules, edge, crypto (with NestJS vectors), architecture, size and docs gates |
| `Test/PAO.IntegrationTests` | Postgres, Redis and S3 from the environment (ADR-0008) | migrator, Redis helpers, RBAC, outbox, scheduler, storage, the full API through TestServer |
| `Test/PAO.E2ETests` | built hosts as processes | start-up smoke of api, worker, migrator |
| `Test/Load` | — | k6 scripts move here at cut-over |
| `Test/PAO.TestKit` | — | `TestEnvironment` (`PAO_TEST_*`), private databases from a migrated template, fakes |

Each integration test class gets a private database (`pao_net_test_*`) and its own Redis
key environment; nothing shared is dropped.

## Gates (`./pao dotnet ci`, `backend-dotnet/scripts/ci.sh`)

1. `dotnet build` with warnings as errors (analyzers, CS1591 XML docs).
2. `dotnet format --verify-no-changes`.
3. Gate tests: architecture rules (NetArchTest), authorisation attributes, size limits,
   docs coverage.
4. Unit and integration tests with Microsoft code coverage, merged by
   `scripts/coverage.py`, gated at 100% line coverage. Only generated code and the three
   `Program.cs` files are excluded (`coverage.config`).
5. The bundled spec is current (`scripts/gen-spec.sh --check`; the contract folder is the MSBuild property `PaoApiDir`).
6. E2E start-up smoke tests.
