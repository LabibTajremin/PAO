# PAO

PAO is a mobile marketplace for Bangladesh. It connects customers with verified local
service providers — electricians, plumbers, AC technicians, home salon and drivers — at
fixed, platform-set prices. Customers choose a provider nearby; the provider accepts,
arrives, starts the job with the customer's 4-digit code and is paid in cash.

Three clients share one NestJS (TypeScript) API:

| App | Who | Where |
|---|---|---|
| PAO | Customers | `frontend/apps/customer` (Flutter, Android + iOS) |
| PAO Partner | Service providers | `frontend/apps/partner` (Flutter, Android + iOS) |
| PAO Admin | Operations staff | `frontend/apps/admin` (Flutter Web) |

## Run it locally

Requirements: Docker, Node.js 22.12+, sqlc 1.27+ (for `./pao gen`), Flutter 3.47+ (for the
apps), bash.

```sh
./pao setup   # checks tools, installs npm packages and git hooks, creates .env
./pao up      # PostgreSQL+PostGIS, Redis, S3 storage, API and worker — all healthy
./pao seed    # migrations + the 5 MVP services and demo users
curl localhost:8080/healthz
```

Run the whole quality gate (what CI runs) with `./pao ci`. `./pao help` lists every command.

## Folder map

| Path | What it holds |
|---|---|
| `api/openapi.yaml` | REST contract shared by backend and apps |
| `backend/` | NestJS modular monolith: `src/main.ts`, `src/worker.ts`, `src/migrate.ts`, `src/platform/`, `src/modules/<module>/`, `migrations/`, `seed/` |
| `frontend/` | Flutter workspace: `apps/` (customer, partner, admin) and `packages/` (pao_core, pao_api, pao_ui, pao_l10n, pao_e2e); per-app `config/<flavour>.json` |
| `test/` | Cross-system tests: e2e journeys, fixtures, performance scripts, CLI tests |
| `docs/` | PRD, build kit, ADRs, architecture, glossary, runbooks |
| `scripts/` | `pao` CLI helpers, git hooks and `build-release.sh` |
| `.github/workflows/` | CI: backend, frontend, contract, e2e |

## Documentation

- Product requirements: [`docs/prd/PAO-PRD.pdf`](docs/prd/PAO-PRD.pdf)
- Handover (start here when taking over): [`HANDOVER.md`](HANDOVER.md)
- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Release builds and signing: [`docs/release.md`](docs/release.md)
- Domain glossary: [`docs/domain-glossary.md`](docs/domain-glossary.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Build progress (AI build kit): [`docs/build/PROGRESS.md`](docs/build/PROGRESS.md)
- UI designs: [Figma](https://www.figma.com/design/ytbbSEIF1I6cZN0iWJVQsC)
