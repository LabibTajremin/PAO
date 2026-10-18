# PAO.AI — agent instructions for the .NET backend

Read this before changing anything under `backend-dotnet/` (later `Backend/`). The repo-wide
rules in `CLAUDE.md` and `docs/build/` still apply; ADR-0034 is the source of these rules.

## Layout

```
PAO.sln  global.json  Directory.Build.props  Directory.Packages.props (every version pinned)
Config/            one JSON file per concern, defaults only, never secrets
DB Changes/        goose SQL scripts per module + modules.json — the only schema source
Docs/              Areas/<Area>/, Architecture/, Config/, Database/, Operations/, Testing/, Api/
Logs/              runtime logs, Logs/<yyyy-MM-dd>/pao-<host>.log (git-ignored)
PAO.Core/          web API: Areas/<Area>/{Controllers,Features,Services,Repositories}, Registration/
PAO.Lib/           request/view models, DTOs, events, error reasons, mapping, validation, mediator contracts
PAO.EF/            PaoDbContext, db models, IEntityTypeConfiguration, design-time factory
PAO.Infrastructure/ platform (config, logging, Redis, crypto, HTTP edge, outbox, …), Registration/
PAO.BackgroundJobs/ scheduler, relay loop, platform jobs
PAO.Worker/  PAO.Migrator/   the other two hosts
Tools/PAO.Gates/   size and docs checkers
Test/              PAO.UnitTests, PAO.IntegrationTests, PAO.E2ETests, PAO.TestKit, Load/
scripts/           ci.sh, coverage.py, gen-spec.sh
```

## Rules

- **Areas.** One ASP.NET area per module. An area reaches another only through that area's
  `Services/Shared/I<Area>SharedService`; architecture tests enforce it.
- **CQRS.** One use case = one folder `Features/<Feature>/Commands|Queries/` with the request
  (`ICommand<T>`/`IQuery<T>`), its FluentValidation validator and its handler. Controllers
  take only `IMediator`. Logic shared by several handlers goes to the area's `Services/`;
  data access to `Repositories/` (EF Core).
- **Models.** Request models in, view models out, db models in PAO.EF. Convert with
  `IMapper` and an `IMappingProfile` per area in PAO.Lib. The mediator scan registers every
  PAO.Lib profile; do not add one in `Add<Area>Area` (a gate checks it). No AutoMapper,
  MediatR or other paid library.
- **No N+1.** Never query in a loop: `BatchLoader.LoadMany`, `Include`/projection,
  `ReferenceDataCache` for small reference data.
- **Authorisation.** Every action has one of `[Admin(Permission=…)]`, `[Customer(…)]`,
  `[Merchant(…)]`, `[AllUserType]`, `[AllowAnonymous]`, matching the spec's `x-permission`
  (tests fail otherwise). "Merchant" = provider; API paths stay `/v1/provider/...`.
- **Request bodies.** Take the body as a `[FromBody] T body` parameter. The edge binds it from
  the already-parsed JSON without failing, so authorisation answers 401/403 before any
  body error, and spec validation answers 422 after it (`Docs/Architecture/http-edge.md`).
  Never read `Request.Body` or `HttpContext.Edge().Body` in a controller.
- **Behaviour.** Port behaviour from NestJS (`backend/`): same use-case names, error codes,
  events, tables, Redis keys, env vars. The PRD wins on behaviour.
- **Registration.** `Program.cs` only calls `AddPaoSettings`, `AddBuiltInServices`,
  `AddCustomServices`, `AddDatabase`, `AddRepositories`, `Add<Area>Area`; each lives in its own
  file under `Registration/` and is tested.
- **Docs.** Every public type and member has XML docs (CS1591 is an error). Every area,
  feature, controller, service, repository, job, config section and script has a page or
  index entry under `Docs/`; the docs gate fails otherwise.
- **Comments** explain why, never what. No narration, no TODO without an issue.
- **Config.** Typed options from `Config/*.json`; secrets from the environment only.

## Size limits

C# files ≤ 250 lines (tests ≤ 400), methods ≤ 40 lines — `SizeChecker` enforces them.

## Adding a feature

1. Request + validator + handler in `Areas/<Area>/Features/<Feature>/Commands|Queries/`;
   DTOs and view models in `PAO.Lib/Areas/<Area>/`, maps in a mapping profile.
2. Repository methods in `Areas/<Area>/Repositories/`, registered in `AddRepositories`;
   entities and configurations in `PAO.EF/<Area>/`.
3. A controller action in `Areas/<Area>/Controllers/` with `[Area("<Area>")]`, the spec path
   and the attribute for its `x-permission`, calling only `IMediator`.
4. Unit and integration tests (100% coverage), the entries in `Docs/Areas/<Area>/`.
5. `./pao dotnet ci` must pass.
