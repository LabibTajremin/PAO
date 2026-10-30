# infra/e2e

The end-to-end stack the journeys run against (P14, `docs/build/03-testing.md` §1): the
api, worker and migrate services are the .NET hosts built from `Backend/docker/Dockerfile`.

- `stack.sh` starts a fresh stack as the separate compose project `pao-e2e`
  (`compose.e2e.yml` over `infra/docker-compose.yml`): API on `:8180`, S3 on `:9100`,
  worker hooks on `:9191` (move them with `PAO_E2E_PROJECT` and `PAO_E2E_PORT` to run
  several stacks), an empty database, `APP_ENV=test`. It seeds the catalog and the demo
  admins with a random password and writes the endpoints to `out/e2e/.stack.env`
  (`PAO_E2E_STATE` moves the folder).
- With `APP_ENV=test` the API and worker mount test-only hooks
  (`Backend/PAO.Infrastructure/Testing/TestHooks.cs`): `GET /__test/sms?phone=` (the last
  text, for one-time codes), `GET /__test/pushes?token=` (on the worker, pushes sent to a device
  token) and `POST /__test/verification/expire?at=` (the expiry sweep as of a time).
- The black-box API journeys are C# in `Backend/Test/PAO.E2ETests/Journeys` (xUnit, trait
  `Category=Journey`): plain HTTP, no backend references. Admins sign in with the seeded
  password and a TOTP code; their enrolment secrets are kept in `out/e2e/.admins.env` for
  later runs against the same stack. Each actor sends `X-Forwarded-For` with its own
  address (the API trusts it from the private Docker network), so per-IP limits such as
  10 login codes an hour see separate devices rather than one test runner.
- Journeys: onboarding, booking (happy path with extras, ratings, receipt, earnings and
  the request push), reject / timeout / cancel exits, document expiry and renewal, bans,
  RBAC per admin role, request → push latency (PRD §11) and a smoke test of the stack's
  api, worker and migrate entry points.
- `Frontend/test/e2e/run.sh` drives the Flutter apps' journeys against the same stack.

Run everything with `./pao test e2e`, or `infra/e2e/stack.sh` once and then, while
iterating:

```sh
cd Backend && dotnet test --project Test/PAO.E2ETests -- --filter-trait "Category=Journey"
dotnet test --project Test/PAO.E2ETests -- --filter-class "PAO.E2ETests.Journeys.BookingJourney"
```

Behind a TLS-intercepting proxy, copy its CA bundle into the project (for example
`infra/local-ca.pem`, which is ignored) and set `PAO_EXTRA_CA_FILE=./infra/local-ca.pem` so
the image build can restore NuGet packages (an absolute path works too). The admin journey
needs `CHROMEDRIVER` and `CHROME_EXECUTABLE` of the same major version.
