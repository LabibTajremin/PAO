# P11 — Partner app

**Goal:** the provider app (`apps/partner`) is complete and works against the real API.
Built before the customer app because the platform needs verified providers first (PRD §12).

**Read first:** PRD §6, §7.2, §8.2, §8.5; `05-screens.md` partner table; Figma page
"Merchant App (Provider)".

## Features (one folder each under `lib/features/`)

| Feature | Screens | Notes |
|---|---|---|
| `onboarding` | M01, M02 | language choice persisted |
| `auth` | M03, M04 | OTP with resend timer and wrong-code state |
| `enrolment` | M05–M13 | resumable wizard; camera capture for NID and live selfie; uploads via signed URLs with progress and retry |
| `verification` | M14 | per-item status, rejection reasons, re-upload; the gate screen |
| `home` | M15, M15b | online toggle, heartbeat while online (foreground service on Android), today's earnings, active job card, expiry banner |
| `requests` | M16 + reject sheet + expired | full-screen request opened from push; countdown from server deadline |
| `job` | M17–M21 | status actions, Google Maps hand-off (P-07), call, start code entry, extra items picker, cash received, rate customer |
| `jobs` | M23–M25 | upcoming/past, detail timeline, report a problem |
| `earnings` | M26, M27 | daily/weekly/monthly, by job |
| `profile` | M28–M36 | public preview, reviews, documents + expiry, badge & level, services & area, language, help, log out |
| `notifications` | push handling | FCM token registration; tap routes to the right screen |

Each feature: `data/` repository using `pao_api`, `domain/` entities and use cases,
`presentation/` cubits + pages. Every screen handles loading, empty, error and offline.

## Tests

- Bloc tests for every cubit state transition; widget tests for every page state.
- Patrol journeys in `integration_test/`, run against the real Docker stack (`./pao up` +
  seed), never against mocked HTTP: enrol → verification pending → (admin approves via
  seed API) → go online → accept → start code → complete → rate. P14 adds them to CI.

## Definition of done

A new provider can enrol, get approved by an admin (via API seed script), go online,
receive, accept and complete a job on a device/emulator. `./pao ci` green; PR merged.
