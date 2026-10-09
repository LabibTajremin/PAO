# PAO

PAO is a mobile marketplace for Bangladesh. It connects customers with verified local
service providers — electricians, plumbers, AC technicians, home salon and drivers — at
fixed, platform-set prices. Customers choose a provider nearby; the provider accepts,
arrives, starts the job with the customer's 4-digit code and is paid in cash.

Three clients share one Go API:

| App | Who | Where |
|---|---|---|
| PAO | Customers | `frontend/apps/customer` (Flutter, Android + iOS) |
| PAO Partner | Service providers | `frontend/apps/partner` (Flutter, Android + iOS) |
| PAO Admin | Operations staff | `frontend/apps/admin` (Flutter Web) |

## Run it locally

Requirements: Docker, Go 1.27+, Flutter 3.47+ (for the apps), bash.

```sh
./pao setup   # checks tools, installs git hooks, creates .env from .env.example
./pao up      # PostgreSQL+PostGIS, Redis, S3 storage, API and worker — all healthy
./pao seed    # migrations + the 5 MVP services and demo users
curl localhost:8080/healthz
```

Run the whole quality gate (what CI runs) with `./pao ci`. `./pao help` lists every command.

## Folder map

| Path | What it holds |
|---|---|
| `api/openapi.yaml` | REST contract shared by backend and apps |
| `backend/` | Go modular monolith: `cmd/` (api, worker), `internal/platform/`, `internal/modules/<module>/`, `migrations/`, `seed/` |
| `frontend/` | Flutter workspace: `apps/` (customer, partner, admin) and `packages/` (pao_core, pao_api, pao_ui, pao_l10n) |
| `test/` | Cross-system tests: e2e journeys, fixtures, performance scripts, CLI tests |
| `docs/` | PRD, build kit, ADRs, architecture, glossary, runbooks |
| `scripts/` | `pao` CLI helpers and git hooks |
| `.github/workflows/` | CI: backend, frontend, contract, e2e |

## Documentation

- Product requirements: [`docs/prd/PAO-PRD.pdf`](docs/prd/PAO-PRD.pdf)
- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Domain glossary: [`docs/domain-glossary.md`](docs/domain-glossary.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Build progress (AI build kit): [`docs/build/PROGRESS.md`](docs/build/PROGRESS.md)
- UI designs: [Figma](https://www.figma.com/design/ytbbSEIF1I6cZN0iWJVQsC)
