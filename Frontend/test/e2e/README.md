# Frontend/test/e2e

The Flutter apps' end-to-end journeys and start-up smoke tests (P14 tasks 3 and 5),
driven against the running stack (`infra/e2e/stack.sh`). `./pao test e2e` runs them
after the API journeys; `run.sh` runs them alone.

| App | Runs on | Files (`Frontend/apps/<app>/integration_test/`) |
|---|---|---|
| partner | Linux desktop, Xvfb | `smoke_test.dart`, `partner_journey_test.dart` |
| customer | Linux desktop, Xvfb | `smoke_test.dart`, `customer_journey_test.dart` (two journeys) |
| admin | Chrome, `flutter drive` + chromedriver | `smoke_test.dart`, `admin_journey_test.dart` |

- Journeys use `package:integration_test` (no Patrol: it needs native emulators) and
  build `AppServices` the way `main.dart` does, against the stack URL. Only device
  services with no Linux implementation are stand-ins (`package:pao_e2e`: fixed GPS
  in Banani, a stub camera, no push, in-memory session store); network and UI are
  real.
- Smoke tests run the real `main()`: the composition root that unit coverage
  excludes. On Linux they need a D-Bus session and an unlocked keyring for
  `flutter_secure_storage`, which `desktop-session.sh` provides; connectivity_plus
  cannot reach NetworkManager there, and that error alone is tolerated.
- What the apps do not drive is done over plain HTTP, as in `Backend/Test/PAO.E2ETests`
  (`package:pao_e2e`): reading one-time codes from `GET /__test/sms`, the verifier's
  approvals (password + TOTP, secrets shared in `out/e2e/.admins.env`), the online
  provider customers book, and the provider's side of a job. The browser can neither
  read the SMS capture nor write files, so `admin-web.sh` first runs
  `dart run pao_e2e:submitted_provider` for a provider waiting in the queue.
- Each simulated device sends its own `X-Forwarded-For` address (the API trusts it
  from Docker's gateway), so the per-address limit on one-time codes is not shared.

## Running

```sh
infra/e2e/stack.sh                       # or with PAO_E2E_PROJECT / PAO_E2E_PORT
Frontend/test/e2e/run.sh                  # all apps
Frontend/test/e2e/run.sh customer -- integration_test/customer_journey_test.dart
```

Needs Flutter, `xvfb-run`, `dbus-run-session`, `gnome-keyring` and the Linux desktop
toolchain (clang, cmake, ninja, GTK 3, libsecret, libcurl for Sentry's native SDK) for partner and customer; Chrome and
a matching chromedriver (`CHROMEDRIVER`, `CHROME_EXECUTABLE`) for admin. The admin
panel is served on `PAO_E2E_ADMIN_WEB_PORT` (default 5000), which must be the stack's
`ADMIN_CORS_ORIGIN` port; start a stack for another port with
`ADMIN_CORS_ORIGIN=http://localhost:5480 infra/e2e/stack.sh`.
