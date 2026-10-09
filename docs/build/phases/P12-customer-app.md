# P12 — Customer app

**Goal:** the customer app (`apps/customer`) is complete and works against the real API.

**Read first:** PRD §5, §7.1, §8.1, §8.4; `05-screens.md` customer table; Figma page
"Customer App (Main)" sections 01–12 (section 13 is out of scope, D15/D16).

## Features (one folder each under `lib/features/`)

| Feature | Screens | Notes |
|---|---|---|
| `onboarding` | C01, C02, C31, C32 | 3 slides, language |
| `auth` | C03–C05, C33, C63 | OTP, profile setup, welcome back |
| `location` | C06, C34, C35 | permission prompt, map pin, address search (maps port), area check |
| `home` | C07, C37 | categories, search bar, active-booking banner (jumps to live booking) |
| `search` | C08, C38 | debounced search, no-results state |
| `service` | C09, C43, C44 | sub-services, quantity, inclusions; women-only note; driver date/time/duty |
| `providers` | C10, C11, C39–C42 | list, sort/filter, empty state, profile, badge explainer, reviews |
| `booking` | C12, C45, C46, C13, C13b, C47, C48 | setup (ASAP/scheduled), address picker, idempotent create, waiting countdown, declined/timeout → back to list |
| `live` | C49, C14, C50, C51, C15, C16 | status stepper driven by push + polling fallback, start code display (screenshots blocked), extras approval, completion |
| `cancel` | C52–C54 | reason list, result, blocked after start |
| `rating` | C17, C55 | stars, tags, comment |
| `bookings` | C18, C18b, C58, C19, C57, C64 | upcoming/past, detail timeline, receipt (share as PDF) |
| `report` | C20, C56 | reason, description, photos |
| `notifications` | C21, C59 | inbox, push tap routing |
| `account` | C22–C30, C61, C62 | profile, addresses, language, help, legal, delete with OTP, log out |
| `connectivity` | C36 | global offline banner; start code cached for offline display |

## Tests

- Bloc tests for every cubit; widget tests for every page state (loading, empty, error,
  offline, success).
- Patrol journeys added in `integration_test/`: sign up → book → see accepted → share
  code → approve extras → complete → rate; cancel before start; timeout path.

## Definition of done

The full happy path and every exit work on an emulator against `./pao up`.
`./pao ci` green; PR merged.
