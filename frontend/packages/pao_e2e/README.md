# pao_e2e (`packages/pao_e2e`)

Test support for the app journeys in `apps/*/integration_test` (P14). Not used by
any app at run time; apps list it under `dev_dependencies`.

- `stack.dart` (pure Dart): the e2e stack over plain HTTP, as `test/e2e/api` does it —
  `StackClient` (one-time codes from `/__test/sms`, a client address per device),
  `PartnerDriver` (sign-in, enrolment with uploads, presence), `AdminDriver`
  (password + TOTP sign-in, approvals), `JobDriver` (the provider's side of a job),
  `totp()`.
- `pao_e2e.dart`: the above plus device stand-ins (`FixedLocation`, `StubPhotos`) and
  UI helpers that wait for what the user would see (`pumpUntil`, `tapText`,
  `typeInto`, `enterCode`).
- `secrets_file.dart` (`dart:io`): admins' TOTP secrets in `test/e2e/.admins.env`.
- `bin/submitted_provider.dart`: a provider waiting for review, for the admin journey.

How the journeys run: `test/e2e/mobile/README.md`.
