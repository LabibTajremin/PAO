# test/e2e

End-to-end journeys against the full Docker stack (P14, `docs/build/03-testing.md` §1).

- `stack.sh` starts a fresh stack as the separate compose project `pao-e2e`
  (`compose.e2e.yml`): API on `:8180`, S3 on `:9100`, worker hooks on `:9191` (move them
  with `PAO_E2E_PROJECT` and `PAO_E2E_PORT` to run several stacks), an empty
  database, `APP_ENV=test`. It seeds the catalog and the demo admins with a random
  password and writes the endpoints to `.stack.env`.
- With `APP_ENV=test` the API and worker mount test-only hooks
  (`backend/internal/app/testhooks.go`): `GET /__test/sms?phone=` (the last text, for
  one-time codes), `GET /__test/pushes?token=` (on the worker, pushes sent to a device
  token) and `POST /__test/verification/expire?at=` (the expiry sweep as of a time).
- `api/` is a Go module of black-box journeys: plain HTTP, no backend packages. Admins
  sign in with the seeded password and a TOTP code; their enrolment secrets are kept in
  `.admins.env` for later runs against the same stack.
- `mobile/` drives the Flutter apps' journeys against the same stack.

Run everything with `./pao test e2e`, or `test/e2e/stack.sh` once and then
`(cd test/e2e && go test ./...)` while iterating.
