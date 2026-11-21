# PAO

PAO is a mobile marketplace for Bangladesh. It connects customers with verified local
service providers — electricians, plumbers, AC technicians, home salon and drivers — at
fixed, platform-set prices. Customers choose a provider nearby; the provider accepts,
arrives, starts the job with the customer's 4-digit code and is paid in cash.

Three clients share one .NET 10 (C#) API:

| App | Who | Where |
|---|---|---|
| PAO | Customers | `Frontend/apps/customer` (Flutter, Android + iOS) |
| PAO Partner | Service providers | `Frontend/apps/partner` (Flutter, Android + iOS) |
| PAO Admin | Operations staff | `Frontend/apps/admin` (Flutter Web) |

## Run it locally

You'll need Docker, the .NET SDK pinned in `Backend/global.json`, Flutter 3.47+ (for the
apps), bash; Node.js (`npx`) only for `./pao gen`, which bundles the OpenAPI contract.

```sh
./pao setup   # checks tools, restores NuGet packages, installs git hooks, creates .env
./pao up      # PostgreSQL+PostGIS, Redis, S3 storage, API and worker — all healthy
./pao seed    # migrations + the 5 MVP services and demo users
curl localhost:8080/healthz
```

Run the whole quality gate (what CI runs) with `./pao ci`. `./pao help` lists every command.

## Folder map

| Path | What it holds |
|---|---|
| `PAO.sln` | The one .NET solution. Open it in Visual Studio, or open `PAO.code-workspace` in VS Code |
| `Backend/` | The .NET API, worker and migrator: `src/`, `tests/`, `tools/`, the contract in `api/`, `config/`, `database/`, `docs/`. See [`Backend/README.md`](Backend/README.md) |
| `Frontend/` | The Flutter apps (customer, partner, admin) and their shared packages; `e2e/` runs the app journeys. See [`Frontend/README.md`](Frontend/README.md) |
| `design/` | The logo, app icons, illustrations, service icons and the owner's references |
| `docs/` | Guides, ADRs, the PRD, runbooks and the build plan. See [`docs/README.md`](docs/README.md) |
| `infra/` | The Docker stack, the e2e stack, monitoring and the security scanner settings |
| `tools/` | What `./pao` runs, the git hooks and the release build script |
| `.vscode/` | Recommended extensions, run configurations and tasks |
| `out/` | Generated and ignored: coverage, the perf fixture, the e2e stack's state |
| `.github/workflows/` | CI: backend, frontend, contract, e2e |

New here? [`docs/guides/getting-started.md`](docs/guides/getting-started.md) goes from clone to
running apps.

## Documentation

- Product requirements: [`docs/prd/PAO-PRD.pdf`](docs/prd/PAO-PRD.pdf)
- Handover (start here when taking over): [`docs/HANDOVER.md`](docs/HANDOVER.md)
- Architecture: [`docs/guides/architecture.md`](docs/guides/architecture.md)
- Release builds and signing: [`docs/guides/release.md`](docs/guides/release.md)
- Deployment (Vercel admin web, backend services, mobile builds): [`docs/guides/deployment.md`](docs/guides/deployment.md)
- Domain glossary: [`docs/guides/domain-glossary.md`](docs/guides/domain-glossary.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Contributing: [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md)
- Build progress (AI build kit): [`docs/build/PROGRESS.md`](docs/build/PROGRESS.md)
- UI designs: [Figma](https://www.figma.com/design/ytbbSEIF1I6cZN0iWJVQsC)
