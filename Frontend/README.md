# Frontend

The three Flutter apps and the packages they share, in one Dart workspace.

| Folder | What's in it |
|---|---|
| `apps/customer` | **PAO**, the customer app (Android, iOS) |
| `apps/partner` | **PAO Partner**, the app for service providers and merchants (Android, iOS) |
| `apps/admin` | **PAO Admin**, the operations panel (web) |
| `packages/pao_core` | Networking, session, permissions, push, routing guards |
| `packages/pao_ui` | The design system: colour tokens, themes, shared widgets |
| `packages/pao_l10n` | Shared English and Bangla strings |
| `packages/pao_api` | The API client, generated from `Backend/api/openapi.yaml`. Don't edit it by hand |
| `packages/pao_e2e` | Helpers for the app journeys |
| `e2e/` | Scripts that run the app journeys against the e2e stack |

Every app splits features the same way: `lib/features/<feature>/{domain,data,presentation}`.
`apps/customer/lib/features/auth` is the reference to copy.

## Run an app

Start the backend first (`./pao up && ./pao seed` from the root), then:

```sh
cd Frontend/apps/customer
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The dev config points at `10.0.2.2:8080`, which is your computer as seen from the Android
emulator. On an iOS simulator or a phone, change `PAO_API_BASE_URL` in `config/dev.json`
locally. In VS Code, pick **Customer app (dev)**, **Partner app (dev)** or **Admin web (dev)** from
the run menu.

## Test it

```sh
./pao test dart     # unit and widget tests of every package (from the root)
./pao cover dart    # the same, with the 100% coverage check
```

## Open these first

1. `packages/pao_ui/lib/src/tokens/`: colours, spacing and type
2. `apps/customer/lib/app/router.dart`: every screen and how you get there
3. `apps/customer/lib/features/auth/`: a complete feature
