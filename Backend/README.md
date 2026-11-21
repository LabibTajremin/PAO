# Backend

The .NET 10 API that the customer, partner and admin apps talk to, plus the worker that
runs background jobs and the migrator that owns the database. All projects are in the
root `PAO.sln`.

## Where things live

| Folder | What's in it |
|---|---|
| `src/` | The code: `PAO.Core` (API host and every business area), `PAO.Worker`, `PAO.Migrator`, `PAO.Lib` (contracts), `PAO.EF` (database model), `PAO.Infrastructure` (platform), `PAO.BackgroundJobs` |
| `tests/` | `PAO.UnitTests`, `PAO.IntegrationTests`, `PAO.E2ETests`, `PAO.LoadTests`, and `PAO.TestKit` (shared fakes) |
| `tools/` | `PAO.Gates`, the size and docs checkers the unit tests run |
| `api/` | The OpenAPI contract. Change it first, then the code |
| `config/` | Non-secret settings, one JSON file per concern; secrets come from environment variables |
| `database/` | `changes/`: the SQL that creates the schema, one folder per area; `seed/`: the catalog and demo data |
| `docs/` | How each area, the config, the database and operations work; `conventions.md` has the rules for writing code here |
| `docker/`, `scripts/` | The image, and the scripts CI runs (`scripts/ci.sh`) |

A request goes: controller in `src/PAO.Core/Areas/<Area>/Controllers` → a feature handler in
`Features/<UseCase>` → a repository in `Repositories`. Areas never call each other directly;
they go through `Services/Shared/I<Area>SharedService` or events. The architecture tests
enforce this, so the build tells you when a shortcut crosses a line.

## Run it

From the repository root:

```sh
./pao up      # Postgres, Redis, storage, API and worker in Docker
./pao seed    # schema and demo data
curl localhost:8080/healthz
```

To run the API from your editor instead (breakpoints, hot reload), keep `./pao up` running
for the databases, copy `appsettings.Local.example.json` to `appsettings.Local.json`, and start
**API (PAO.Core)** from the VS Code run menu, or `dotnet run --project src/PAO.Core` here.

## Test it

```sh
scripts/ci.sh unit    # build and unit tests, no Docker needed
scripts/ci.sh all     # everything CI runs for the backend; needs ./pao up
```

## Open these first

1. `docs/conventions.md`: the rules (file sizes, layout, naming)
2. `src/PAO.Core/Areas/Booking/`: a complete area to copy from
3. `api/openapi.yaml`: what the apps can call
