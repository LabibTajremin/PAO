# PAO handover

This is the document to read first when taking over PAO. It says what exists, how to
run, test and release it, what is known to be missing, and what the owner still has to
decide or supply before launch.

## System overview

PAO is a home-services marketplace for Dhaka: customers book verified providers
(electrician, plumber, AC technician, home salon, driver hire) at fixed prices and pay
cash (PRD; ADRs 0011–0014).

| Part | Where | Technology |
|---|---|---|
| API, worker, migrator | `Backend/` | .NET 10 (C#) modular monolith, ASP.NET Core areas (ADR-0001, ADR-0034) |
| Contract | `Backend/Api/openapi.yaml` | OpenAPI 3.1; drives request validation, RBAC (`x-permission`) and the generated Dart client |
| Customer app (PAO) | `Frontend/apps/customer` | Flutter, Android + iOS |
| Partner app (PAO Partner) | `Frontend/apps/partner` | Flutter, Android + iOS |
| Admin console | `Frontend/apps/admin` | Flutter Web (ADR-0018) |
| Shared Flutter code | `Frontend/packages/` | `pao_core`, `pao_ui`, `pao_l10n`, `pao_api` (generated), `pao_e2e` |
| Data | — | PostgreSQL 16 + PostGIS (one schema per module), Redis 7, S3-compatible storage |

The backend has twelve modules, each an ASP.NET area (identity, customer, provider as
`Merchant`, verification, catalog, booking, rating, notification, media, admin, audit,
billing). Each exposes only its shared service (`Services/Shared/I<Area>SharedService`),
owns one schema, and publishes events through its own outbox. [`docs/guides/architecture.md`](guides/architecture.md) has the module map,
boundary rules and how to extract a module into a service; every area is documented in
`Backend/Docs/Areas/<Area>/` (agent rules in `Backend/PAO.AI/README.md`), every app and
package has a README beside its `pubspec.yaml`.

Third parties sit behind ports with local fakes (ADR-0019): SMS (`SMS_ADAPTER=console |
sslwireless`), push (`PUSH_ADAPTER=log | fcm`), maps (customer app, Google Geocoding),
storage (S3). Production refuses the fake SMS and push adapters.

## Run, test, release

```sh
./pao setup          # tools, NuGet restore, git hooks, .env with fresh local keys
./pao up && ./pao seed
./pao ci             # lint, generated-code drift, unit + integration + e2e, 100% coverage, security
./pao perf           # k6: nearby search at 50 rps, p95 < 300 ms
```

- Testing strategy and gates: [`docs/build/03-testing.md`](build/03-testing.md).
  Integration tests need the compose Postgres/Redis/RustFS (ADR-0008); the e2e stack is
  `infra/e2e/stack.sh` (ADR-0031).
- Release builds, flavours (dev/staging/prod), signing, versioning and the store
  checklist: [`docs/guides/release.md`](guides/release.md).
- Conventions (file and function limits, comments, naming):
  [`docs/build/01-conventions.md`](build/01-conventions.md).
- Deployment guide (admin web on Vercel, backend hosting, env vars, mobile config):
  [`docs/guides/deployment.md`](guides/deployment.md).
- Operations — forthcoming from the P16 operations work: runbooks in `docs/runbooks/`
  (deploy, rollback, JWT key rotation, database restore, incidents), the verification
  process in `docs/guides/verification.md`, Grafana dashboards and alert rules as code, and
  Sentry behind an `ErrorReporter` interface. Security — forthcoming from the P16
  security work: `docs/guides/security-checklist.md` (ASVS L2 / MASVS-L1), IDOR and privacy
  tests, certificate pinning on release builds and the document-retention purge job.
  Check those paths once P16 is merged.

## Known limitations

From ADRs 0026–0032 and the build log:

- **Background presence on iOS.** Android keeps the partner heartbeat alive with a
  foreground service while online (`PresenceService.kt`); iOS has no equivalent, so a
  provider who backgrounds the app on iOS drops offline after the 90 s presence expiry
  (fails safe; ADR-0028).
- **Native code not exercised by automated tests.** FLAG_SECURE on the start code,
  camera, GPS, FCM and the presence service run only on devices; app journeys run on
  Linux desktop and Chrome (ADR-0031). The Android and iOS release builds are verified
  in CI only, not in the build container. An emulator job is a follow-up.
- **Customer app (ADR-0029).** No native map (the pin is placed on a drawn frame); the
  receipt PDF is English only; nearby search uses the first item of a multi-item
  booking; waiting and live screens poll every 5 s instead of using foreground push.
- **Admin console API gaps (ADR-0030).** Level 2 checklists only for super admins;
  sessions and complaints show IDs instead of names; no service filter for verifiers;
  no provider/customer filter on the bookings monitor; no previews of complaint
  evidence photos; assigning complaints needs `admin_user:manage`; no single-service
  admin read.
- **Admin data (ADR-0026).** Face references are not stored, so a ban blocks phone and
  NID only; read models catch up from events, so lists can lag a status change briefly.
- **Backend (ADR-0034).** One worker runs periodic jobs under an advisory lock (request
  expiry is a 15 s sweep, not per booking). The NestJS backend was removed at the P17
  cut-over; its behaviour, tables, Redis keys and env vars carry over unchanged.
- **Placeholders.** Staging and prod API hostnames, support phone and email, app icons,
  and the terms, privacy and FAQ text are drafts.

## Decisions waiting for the owner

- **Proposed — needs owner review:** ADR-0009 (build on one session branch instead of a
  pull request per phase).
- **Accepted defaults the owner may revise** (PRD open questions, ADRs 0010–0025):
  brand names (0010), the five launch services (0011), no revenue model in the MVP
  (0012), cash only (0013), Dhaka with a 5 km radius (0014), provider self-enrolment
  (0015), Level 2 only where flagged (0016), free cancellation until the start code
  (0017), Flutter Web admin (0018), ports with local fakes (0019), women-only home salon
  (0020), 3-minute / 30-minute accept windows (0021), review flags thresholds (0022),
  one-year document retention after closure — to be checked against Bangladeshi law
  (0023), no Phase 2 features (0024), no reschedule or warranty revisits (0025).
- **Release decisions recorded in `docs/guides/release.md`:** final application and bundle
  IDs (the Android and iOS IDs currently differ in form), store names, the staging and
  prod hostnames.

## Launch prerequisites

The owner supplies these; none belong in the repository.

| Item | Where it goes |
|---|---|
| Support phone and email | `Frontend/apps/*/config/prod.json` (`PAO_SUPPORT_PHONE`, `PAO_SUPPORT_EMAIL`) |
| Terms, privacy policy, FAQ (legal review) | app copy (ARB files) and a public privacy-policy URL for the stores |
| Google Maps key (Geocoding, restricted) | CI secret `PAO_MAPS_API_KEY` |
| Firebase project: app configs and a service account | CI secrets `PAO_FCM_*`; backend `PUSH_ADAPTER=fcm`, `FCM_CREDENTIALS_FILE` |
| SMS gateway (SSL Wireless) account and sender ID | backend `SMS_ADAPTER=sslwireless`, `SSLWIRELESS_API_TOKEN`, `SSLWIRELESS_SID` |
| Production secrets | `JWT_SIGNING_KEY`, `DATA_ENCRYPTION_KEY`, S3 credentials, database and Redis URLs, `SEED_ADMIN_PASSWORD` for the first super admin |
| Android upload key, Apple distribution certificate and profiles | CI secrets listed in `docs/guides/release.md` |
| Domains and TLS | API host, admin console origin (`ADMIN_CORS_ORIGIN`), storage host |
| Store accounts | Google Play Console and Apple Developer Program, with reviewer test accounts |
| Error reporting and dashboards | Sentry DSNs and a Grafana/Prometheus endpoint (P16 operations work) |

## Next steps

1. Merge P16, run `./pao ci` and `./pao perf` on a clean clone, and complete the
   security checklist and runbooks.
2. Supply the launch prerequisites above; do a signed staging build from CI, then a
   closed test track (Play internal testing, TestFlight) with real providers in Dhaka.
3. Close the follow-ups above that affect launch quality: app icons, a Bangla receipt,
   the admin API gaps, an Android emulator job for native behaviour.
4. **PRD Phase 2** (ADR-0024 keeps these out of the MVP):
   - Customer: live map tracking of the provider (C-16); digital payment with bKash,
     Nagad and cards (C-17); masked in-app calling and chat (C-18); favourite providers
     and rebook (C-19); SOS and sharing trip status (C-20).
   - Provider: weekly availability schedule (P-14); commission statements and payouts
     to bKash or bank (P-15); Level 2 test booking from the app (P-16).
   - Admin: push notification broadcasts (A-11); finance — commissions, payouts and
     reconciliation (A-12).
   - Safety: masked numbers, live status sharing with family, SOS to operations and the
     emergency contact (PRD §6.5).
   - Later: promo codes and referral (C-21); flat listings and internet packages (C-22).
