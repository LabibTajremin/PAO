# ADR-0031: End-to-end suite

- Status: Accepted
- Date: 2026-10-11
- Source: docs/build/phases/P14-e2e.md

## Context

P14 proves the system end to end through its public surfaces: the HTTP API and the
three apps. It needs a stack it can control (one-time codes, pushes, document
expiry) without weakening production, and it has to run in a container without an
Android SDK.

## Decision

- **Isolated, disposable stack.** `test/e2e/stack.sh` starts a separate compose
  project (default `pao-e2e`, ports 8180/9100/9191, movable with `PAO_E2E_PROJECT` and
  `PAO_E2E_PORT`) from an empty database with a random seed-admin password, so admin
  TOTP enrolment always starts fresh. Enrolment secrets are kept in `.admins.env` for
  reruns against the same stack.
- **Test-only hooks.** With `APP_ENV=test` only, the API and worker mount
  `/__test/sms`, `/__test/pushes` and `/__test/verification/expire`
  (`internal/app/testhooks.go`). Outside test the handler is returned unchanged; the
  config already refuses fake SMS/push adapters in production.
- **Black-box API journeys** in their own Go module (`test/e2e/api`): plain HTTP only.
  They cover onboarding, the booking happy path with receipts and earnings, reject,
  timeout, cancel and blocked cancel, document expiry and renewal, bans, RBAC per
  admin role, a start-up smoke check of the composition roots, and request→provider
  push latency (PRD §11: measured 130–370 ms against the 3 s limit).
- **Simulated devices.** Each actor sends its own `X-Forwarded-For` (trusted only
  from private networks, as in production behind the load balancer), so journeys stay
  inside the per-IP OTP limits.
- **App journeys with `integration_test`, not Patrol.** Patrol needs native
  emulators. The mobile apps run on the Linux desktop under Xvfb with real network
  and UI and stand-ins only for device services (GPS, camera, push, secure storage,
  prefs); the admin panel runs in Chrome via `flutter drive`. Start-up smoke tests run
  each app's real `main()`, tolerating only connectivity_plus's missing-NetworkManager
  error on Linux. Shared helpers live in the `pao_e2e` workspace package under the
  normal 100% gates. Android-only behaviour (FLAG_SECURE, camera, GPS, FCM) is not
  exercised here.
- **Performance in CI.** `./pao perf` (k6, nearby search at 50 rps, p95 < 300 ms;
  measured 15 ms) runs as its own job in `e2e.yml`; the latency journey covers the
  notification target.

## Consequences

- The journeys found and fixed real bugs: emergency-contact codes shared one per-IP
  window across all providers; `reviewedByMe` was never set; new providers saw
  "access denied" before the verification gate; partner permissions were not reloaded
  after Level 1; the admin console could land on "denied" before permissions loaded.
- `./pao ci` now builds and runs the stack, the API journeys and the app journeys.
  Locally the admin web journey needs a chromedriver matching the installed
  Chromium (`CHROMEDRIVER`, `CHROME_EXECUTABLE`); CI uses the runner's Chrome.
- An Android emulator job is a P15 follow-up if device-specific behaviour needs
  automated coverage.
