# ADR-0028: Partner app choices

- Status: Accepted
- Date: 2026-10-10
- Source: docs/build/phases/P11-partner-app.md

## Context

Building the partner app surfaced constraints the phase file does not settle.

## Decision

- **Cubit tests without `bloc_test`.** It pins an analyzer version that conflicts with
  `build_runner` in `pao_api`, so cubits are tested directly against hand-written
  fakes of each feature's domain interface.
- **Heartbeat in the foreground.** Presence heartbeats run from a `Heartbeat`
  interface with a timer implementation while the home screen is alive. A native
  Android foreground service is deferred to P15 hardening; until then a provider who
  backgrounds the app is taken offline by the 90 s presence expiry, which fails safe.
- **Remembered online choice.** There is no presence read endpoint, so the app keeps
  the provider's online choice on the phone and restores it on launch.
- **Dates as strings.** The generated client maps OpenAPI `format: date` to
  `yyyy-MM-dd` strings; `DateTime` serialised with a time part the API rejects.
- **Earnings periods come from the server.** The job list reuses the summary's
  `from`/`to`, so Saturday weeks and Asia/Dhaka days are defined in one place.
- **Support phone from the build.** `--dart-define=PAO_SUPPORT_PHONE` sets the help
  line; operations must supply the real number before launch.
- **App journeys move to P14.** They need the test-only OTP endpoint of the P14 stack
  fixture, so the Patrol journeys for P11–P13 are written there, on top of it.

## Consequences

The P15 hardening phase owns the foreground service. The P14 phase owns device
journeys for all three apps.
