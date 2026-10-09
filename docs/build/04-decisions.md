# Decisions for the build

The PRD (§13) leaves questions open. To keep the build autonomous, the agent uses these
defaults. Each one becomes an ADR in P00 with `Status: Accepted (default — owner may
revise)`. Changing one later means a new ADR, not silent edits.

## Product defaults

| # | Question (PRD §13) | Default for the build |
|---|---|---|
| D1 | Name | Public brand **PAO**; partner app **PAO Partner**; codename `lift` is not used in code. |
| D2 | MVP services | Electrician, Plumber, AC service, Home salon (on-demand); Driver (1-day duration hire only). |
| D3 | Revenue model | Not in MVP. No commission maths; schema leaves room for a `finance` module. |
| D4 | Payment | Cash only. Provider confirms "cash received" at completion. Digital payment is Phase 2 (C-17). |
| D5 | Launch area | Dhaka. Default search radius 5 km, configurable per service (PRD §5). |
| D6 | Recruitment | Self-enrolment through the Partner app. |
| D7 | Level 2 | Required before first booking only for services flagged `requires_level_2` (none of the MVP five). Level 2 still ranks providers higher. |
| D8 | Cancellation | Free for the customer until the start code is entered (PRD §5). Provider cancellation after acceptance is allowed with a reason and counted in quality metrics (PRD §6.4). No fees in MVP. |
| D9 | Admin technology | Flutter Web (`frontend/apps/admin`), sharing `pao_core`, `pao_ui`, `pao_api`. |
| D10 | Third parties | SMS: `SmsSender` port with `console` (dev) and `sslwireless` (prod) adapters. NID: `NidVerifier` port with a `manual` adapter (verifier checks by eye). Maps: Google Maps. Push: FCM with a `log` adapter in dev. |
| D11 | Home-salon gender rule | Home salon is served only by women providers (`provider.gender = female` and service flag `women_providers_only`). Customers cannot pick provider gender for other services in MVP. |
| D12 | Accept time limit | 3 minutes for ASAP, 30 minutes for scheduled; both admin settings (PRD §5). |
| D13 | Quality thresholds | Review flag when rating < 3.5 after 10 jobs, or > 3 provider cancellations in 30 days (PRD §6.4). |
| D14 | Document retention | Kept while active + 1 year after closure (setting), then purged by a job. |
| D15 | Phase 2 / Later features | Out of scope: C-16–C-22, P-14–P-16, A-11–A-12, and the "Phase 2" screens in Figma section 13. Do not build stubs for them. |
| D16 | Reschedule / warranty revisit | Out of scope until the owner adds rules to the PRD (Figma section 13 proposals). |

## Engineering defaults

| # | Topic | Decision |
|---|---|---|
| E1 | Architecture | Modular monolith per PRD §9 (ADR-0001). |
| E2 | Geo search | PostGIS `geography` + GiST index for addresses and provider home base; Redis GEO for live online presence (ADR-0002). |
| E3 | IDs | UUIDv7 everywhere (sortable, safe to expose). Booking display number is a separate sequence. |
| E4 | State management (Flutter) | `flutter_bloc` (ADR-0004). |
| E5 | Auth | JWT access + rotating refresh in Redis (ADR-0005), see `02-architecture.md` §5. |
| E6 | Jobs | River on Postgres; one worker binary (ADR-0006). |
| E7 | Pagination | Cursor (opaque base64 of `(created_at, id)`), default 20, max 100. |
| E8 | Time | Stored UTC (`timestamptz`); formatted Asia/Dhaka in apps. |
| E9 | Money | `int64` paisa; formatted `৳1,130` in apps. |
| E10 | API versioning | `/v1/...`; breaking changes need `/v2`. |
| E11 | Error codes | `{ "error": { "code", "message", "details" } }`; codes are `UPPER_SNAKE` and listed in `api/openapi.yaml` `components/schemas/ErrorCode`. |
| E12 | Design | Figma file below is the visual source of truth; accent colours are a theme token with six presets. |

Figma: <https://www.figma.com/design/ytbbSEIF1I6cZN0iWJVQsC>
