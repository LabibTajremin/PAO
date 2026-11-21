# Getting started

This takes you from a fresh clone to the API running locally and the customer app open on an
Android emulator. Plan for about half an hour, most of it downloads.

## 1. Install the tools

- **Docker** (Docker Desktop on macOS and Windows). The databases and the API run in it.
- **.NET SDK**, the version in `Backend/global.json` (10.0.4xx).
- **Flutter 3.47** with an Android emulator (Android Studio installs one) or Xcode for iOS.
- **Node.js**, only so `./pao gen` can bundle the API contract with `npx`.
- On Windows, use WSL 2 or Git Bash: `./pao` is a bash script.

## 2. Clone and set up

```sh
git clone https://github.com/LabibTajremin/PAO.git
cd PAO
./pao setup
```

`setup` checks the tools above, restores packages, installs the git hooks and creates `.env`
from `.env.example`. The defaults in `.env` work locally; you don't need any real keys.

## 3. Start the backend

```sh
./pao up
./pao seed
curl localhost:8080/healthz
```

`up` starts Postgres, Redis, storage, the API and the worker; `seed` creates the schema and
loads the five starter services and demo users. If the health check answers, the backend is
ready.

Signing in uses a phone number and a one-time code. Locally no SMS is sent: the code is
printed in the API log.

```sh
docker compose -f infra/docker-compose.yml logs -f api
```

## 4. Run an app

```sh
cd Frontend/apps/customer
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

Swap `customer` for `partner` to run the provider app. For the admin panel:

```sh
cd Frontend/apps/admin
flutter run -d chrome --dart-define-from-file=config/dev.json
```

The dev config talks to `10.0.2.2:8080`, which is how the Android emulator reaches your
computer. For an iOS simulator use `localhost:8080`; for a real phone, your computer's
address on the Wi-Fi. Change `PAO_API_BASE_URL` in your local copy of `config/dev.json`.

## 5. Open it in an editor

- **VS Code:** open `PAO.code-workspace` and install the recommended extensions when asked.
  The run menu has the API, worker, migrator and all three apps; **Terminal › Run Task** has
  the build and the `pao` commands.
- **Visual Studio 2022:** open `PAO.sln` from the repository root. Set `PAO.Core` as the startup
  project to run the API. Flutter isn't supported in Visual Studio; use VS Code or Android
  Studio for the apps.

## 6. Before you push

```sh
./pao ci
```

That's the same gate CI runs: lint, architecture rules, every test and 100% coverage. The
pre-commit hook runs the fast part on its own.

## Where next

- `Backend/README.md` and `Frontend/README.md`: how each side is organised
- `docs/guides/architecture.md`: the big picture
- `Backend/docs/conventions.md`: the code rules (they're enforced, so read them early)
