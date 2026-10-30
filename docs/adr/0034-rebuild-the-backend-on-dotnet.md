# ADR-0034: Rebuild the backend on .NET

- Status: Accepted
- Date: 2026-10-17
- Source: owner decision ("PAO C# conversion instructions", handwritten, 2026-10-16);
  docs/build/phases/P17-dotnet-backend.md
- Supersedes: the framework and layout choices in ADR-0032. The HTTP contract,
  database schemas, Redis keys, error codes and events of ADR-0032 stay.

## Context

The owner chose C#/.NET for the backend and gave a concrete layout and pattern set. The
ADR-0032 backend is complete, covered at 100% and proven by the black-box journeys. The
replacement must keep `api/openapi.yaml` so the Flutter apps keep working, and keep the
engineering bar: modular monolith, deny-by-default RBAC, 100% coverage, strict linting.

## Decision

- **Runtime.** .NET 10 (LTS), ASP.NET Core controllers, C# with nullable reference types
  and warnings as errors. EF Core 10 with Npgsql and NetTopologySuite (PostGIS).
- **Repository layout.**
  ```
  Frontend/                 Flutter apps and packages (moved from frontend/)
  Backend/
    PAO.sln
    DB Changes/             versioned SQL scripts, one folder per area (the only schema source)
    Docs/                   backend docs: areas, API notes, runbooks for the .NET stack
    PAO.AI/                 agent instructions and markdown for the backend
    PAO.Core/               the web API: Areas/<Area>/{Controllers,Features,Services,Repositories}
    PAO.Lib/                view models, request models, DTOs, mapping config, validators
    PAO.EF/                 DbContext, db models, entity configuration, context factory
    PAO.Infrastructure/     config binding, auth, Redis, storage, SMS, push, logging, outbox
    PAO.BackgroundJobs/     scheduled jobs (timeouts, expiry, reminders, purges)
    PAO.Worker/             worker service host that runs the jobs and the outbox relay
    PAO.Migrator/           applies `DB Changes` scripts, records versions
    Config/                 non-secret configuration files per concern
    Logs/                   runtime logs, one folder per date (git-ignored)
    Test/
      PAO.UnitTests/  PAO.IntegrationTests/  PAO.E2ETests/  Load/
  ```
  Extra projects are allowed where they keep the solution clean (owner instruction).
- **Areas.** One ASP.NET area per module (Identity, Customer, Merchant, Verification,
  Catalog, Booking, Rating, Notification, Media, Audit, Admin, Billing). An area reaches
  another only through that area's `Shared` service interface; architecture tests enforce
  it, as dependency-cruiser did.
- **Request flow (CQRS).** Controller → handler. Each area has
  `Features/<Feature>/Commands/` and `Features/<Feature>/Queries/`. A handler owns one
  use case and its FluentValidation validator; logic used by several controllers lives in
  the area's `Services/`; data access lives in `Repositories/` (repository pattern over
  EF Core). Dispatch uses a small in-house mediator: MediatR's current licence is
  commercial, and the owner ruled out paid libraries.
- **Models.** Request models (input), view models (output) and db models (EF entities)
  are separate types. A hand-written mapper (`IMapper` plus per-area mapping profiles in
  PAO.Lib) converts between them; no AutoMapper or other paid mapper.
- **Authorisation.** Every controller and action carries an authorisation attribute.
  Role attributes: `[Admin]`, `[Customer]`, `[Merchant]`, `[AllUserType]` and the built-in
  `[AllowAnonymous]`. `[Admin(Permission = "...")]` keeps the fine-grained admin
  permissions from the spec's `x-permission`. A startup test fails if an endpoint has no
  attribute, so access is still deny-by-default. "Merchant" is the owner's name for the
  provider/partner role; API paths stay `/v1/provider/...`.
- **Data.** The existing goose-format SQL migrations move to `Backend/DB Changes` and stay
  the schema source; the migrator applies them and records versions in the same tables,
  so existing databases carry over. EF Core maps to that schema (no EF migrations).
  Queries avoid per-row database calls: batch loads, `Include`/projection, and in-memory
  lookups for small reference data (catalog, settings) cached with invalidation.
- **Configuration.** One file per concern in `Backend/Config` (database, Redis, JWT,
  logging, SMTP, storage/AWS, SMS, push, jobs), bound to typed options and validated at
  start. Files hold defaults and structure only; secrets come from environment variables
  (`Section__Key`), so nothing secret is committed.
- **Logging.** Serilog, JSON to stdout and to `Backend/Logs/<yyyy-MM-dd>/pao-<host>.log`.
- **Service registration.** `Program.cs` of each host only calls named extension methods,
  one concern per method (owner rule, 2026-10-17):
  - `AddBuiltInServices` for framework services: controllers, authentication,
    authorisation, options, logging, health, OpenAPI, rate limiting;
  - `AddCustomServices` for hand-made platform services: mediator, mapper, clock, ids,
    crypto, Redis helpers, storage, SMS, push, outbox;
  - `AddDatabase` for the DbContext, its factory and the connection;
  - `AddRepositories` for the repository registrations;
  - one `Add<Area>Area` per area (for example `AddBookingArea`) for its handlers,
    validators, services and shared contract.

  Each method lives in its own file under the project's `Registration/` folder.
- **Documentation (100% coverage).** `Backend/Docs` is organised folder by folder:
  `Areas/<Area>/` (overview, features, endpoints, data, events), `Architecture/`, `Config/`,
  `Database/`, `Operations/`, `Testing/` and `Api/`.
  - Every area, feature (command or query), controller, service, repository, job,
    configuration file and database script has a documentation page or an entry in its
    folder's index.
  - Every public C# type and member carries XML documentation. `GenerateDocumentationFile`
    is on, and CS1591 is an error. These comments describe the contract (what a caller can
    rely on), while inline comments still explain only *why*.
  - A docs coverage check in CI fails when any area, feature, controller, job, config
    section or script lacks its page, or when a page links to something that no longer
    exists.
- **Quality gates.** `dotnet format` and analyzers (warnings as errors), architecture
  tests, file and method size checks (C# files ≤ 250 lines, methods ≤ 40 lines, tests
  ≤ 400), unit and integration tests merged at 100% line and branch-free statement
  coverage of hand-written code (coverlet), black-box e2e tests, load tests (a C# console app, see below), plus the
  existing security scans. Excluded from coverage, as before: generated code and the
  composition roots (`Program.cs` of each host), which the start-up smoke test covers.
- **Migration path.** Build in `backend-dotnet/` beside the ADR-0032 backend. When its own
  suites pass at 100% and the existing journeys and app journeys pass against it, port the
  journeys to C#, delete the ADR-0032 backend, move `backend-dotnet/` to `Backend/` and
  `frontend/` to `Frontend/`, and switch every gate, hook and workflow.

## Repository layout after cut-over (owner request, 2026-10-17)

The top level shrinks to the places people navigate to, and everything that belongs to a
side lives inside it:

```
.github/            CI workflows
Backend/            the .NET solution (above), plus:
  Api/              the OpenAPI contract (moved from api/). The backend owns and serves
                    the contract. The Flutter client generator and the e2e tests read it
                    from here.
  Test/E2E, Test/Load   black-box journeys (from test/e2e/api) and load tests (from test/perf)
  docker/           backend image files
Frontend/           Flutter apps and packages, plus test/e2e (the app journeys)
docs/               product and project docs: prd/, adr/, build/, guides/ (release,
                    deployment, verification, security checklist, architecture,
                    glossary, booking states), runbooks/, HANDOVER.md, CONTRIBUTING.md
infra/              docker-compose.yml, ops/ (Prometheus, Grafana), security/
                    (gitleaks, trivy and osv-scanner configs)
tools/              the pao CLI internals (from scripts/), git hooks, CLI tests and
                    fixtures (from test/cli, test/fixtures)
pao                 one-line wrapper that runs tools/pao
README.md  LICENSE  CLAUDE.md  .editorconfig  .gitignore  .env.example
```

Files that stay at the root are only those that tools or GitHub look for there: README,
LICENSE, CLAUDE.md (agent entry point), .editorconfig, .gitignore and .env.example (Docker
Compose and the hooks read it). Generated folders (`coverage/`, `.perf-fixture.json`) move
under the ignored `out/`.

`api/` was separate because, in the earlier builds, the spec was a neutral contract
written before any backend existed (P01) and shared by the backend, the generated Dart
client and the journeys. With one backend that owns it, it lives in `Backend/Api`.

## Cut-over as done (P17 task 8, 2026-10-24)

The layout above was applied with these choices where it left room:

- **Journeys.** The black-box journeys are C# in `Backend/Test/PAO.E2ETests/Journeys`
  (the project that already held the start-up smoke tests) rather than a separate
  `Test/E2E` folder: 8 files and 13 tests, the same as the Jest suite they replace. They
  carry the trait `Category=Journey`; `Backend/scripts/ci.sh e2e` filters them out (it runs
  without a stack) and `./pao test e2e` runs them against a fresh stack. They use plain
  HTTP and reference no backend project. The load test is the C# console app `Backend/Test/PAO.LoadTests` (it replaced the k6
  script after cut-over: `HttpClient` at a constant arrival rate, same scenario and
  thresholds, no extra tool to install).
- **The e2e stack** (`stack.sh`, `compose.e2e.yml`) serves both the API and the app
  journeys, so it lives in `infra/e2e/`. Its state (`.stack.env`, `.admins.env`) moved to
  the ignored `out/e2e/` (`PAO_E2E_STATE` overrides it); the perf fixture is
  `out/perf-fixture.json`, coverage `out/coverage/`.
- **Compose** runs with the repository root as its project directory
  (`--project-directory`), so build contexts, the `.env` file and `PAO_EXTRA_CA_FILE` stay
  relative to the root as before. The empty default CA bundle is `infra/no-extra-ca.pem`.
- **Security configs** are `infra/security/{gitleaks.toml,osv-scanner.toml,trivyignore}`,
  passed explicitly by `./pao security`. NuGet lock files (`packages.lock.json`, enabled in
  `Directory.Build.props`) give osv-scanner the .NET dependency graph that the npm
  lockfiles used to provide.
- **Gates.** `./pao ci` runs every stage of `Backend/scripts/ci.sh` exactly once: `lint`
  (build, format, gates), `gen --check` (spec bundle), `test integration` (unit +
  integration with the merged 100% coverage gate) and `test e2e` (start-up smoke, then the
  journeys). `./pao dotnet <stage>` still runs one stage alone.
- **CI.** `dotnet.yml` became `backend.yml` with two jobs: `dotnet` (`ci.sh all`) and
  `tooling` (shellcheck, ops check, CLI tests, security with the image scan), which used
  to run in the previous backend's job.
- **Root.** `./pao` is a two-line wrapper (shebang + `exec tools/pao`); `tools/fixtures`
  stays as the CLI tests' fixture folder.

## Consequences

- The apps, the database and the API contract carry over unchanged, apart from the
  additions in ADR-0035.
- `Backend/` and `backend/` must never coexist in the tree (case-insensitive file systems),
  so the move happens only at cut-over.
- JWTs stay EdDSA (Ed25519) through BouncyCastle, so the key format and env vars carry over.
