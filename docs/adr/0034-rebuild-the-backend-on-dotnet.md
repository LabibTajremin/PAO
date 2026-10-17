# ADR-0034: Rebuild the backend on .NET

- Status: Accepted
- Date: 2026-10-17
- Source: owner decision ("PAO C# conversion instructions", handwritten, 2026-10-16);
  docs/build/phases/P17-dotnet-backend.md
- Supersedes: the NestJS framework and layout choices in ADR-0032. The HTTP contract,
  database schemas, Redis keys, error codes and events of ADR-0032 stay.

## Context

The owner chose C#/.NET for the backend and gave a concrete layout and pattern set. The
NestJS backend is complete, covered at 100% and proven by the black-box journeys. The
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
  coverage of hand-written code (coverlet), black-box e2e tests, load tests (k6), plus the
  existing security scans. Excluded from coverage, as before: generated code and the
  composition roots (`Program.cs` of each host), which the start-up smoke test covers.
- **Migration path.** Build in `backend-dotnet/` beside the NestJS backend. When its own
  suites pass at 100% and the existing journeys and app journeys pass against it, port the
  journeys to C#, delete the NestJS backend, move `backend-dotnet/` to `Backend/` and
  `frontend/` to `Frontend/`, and switch every gate, hook and workflow.

## Consequences

- The apps, the database and the API contract carry over unchanged, apart from the
  additions in ADR-0035.
- `Backend/` and `backend/` must never coexist in the tree (case-insensitive file systems),
  so the move happens only at cut-over.
- JWTs stay EdDSA (Ed25519) through BouncyCastle, so the key format and env vars carry over.
