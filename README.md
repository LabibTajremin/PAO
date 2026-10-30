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

Requirements: Docker, the .NET SDK pinned in `Backend/global.json`, Flutter 3.47+ (for the
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
| `Backend/` | .NET solution (ADR-0034): hosts `PAO.Core` (API), `PAO.Worker`, `PAO.Migrator`; `Api/` (the OpenAPI contract), `Config/`, `DB Changes/`, `Seed/`, `Docs/`, `Test/` (unit, integration, `PAO.E2ETests` journeys, `PAO.LoadTests` load tests), `docker/` |
| `Frontend/` | Flutter workspace: `apps/` (customer, partner, admin) and `packages/` (pao_core, pao_api, pao_ui, pao_l10n, pao_e2e); per-app `config/<flavour>.json`; `test/e2e` (the app journeys) |
| `docs/` | PRD, build kit, ADRs, `guides/` (architecture, release, deployment, glossary, ...), runbooks, handover, contributing |
| `infra/` | `docker-compose.yml`, the e2e stack (`e2e/`), `ops/` (Prometheus, Grafana), `security/` (gitleaks, trivy, osv-scanner configs) |
| `tools/` | the `pao` CLI internals, git hooks, CLI tests, `build-release.sh` |
| `out/` | generated, ignored: coverage, the perf fixture, the e2e stack's state |
| `.github/workflows/` | CI: backend, frontend, contract, e2e |

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
