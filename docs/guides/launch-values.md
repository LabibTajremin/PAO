# Launch values

Every business value that is a placeholder until the owner confirms it, in one place
(ADR-0036). Changing one means editing the files in its row and rebuilding what they feed.
Secrets are not here: they live only in the host's secret store and GitHub secrets
([deployment.md](deployment.md#gaps-to-close-before-launch)).

| Value | MVP placeholder | Status | Where it is set |
|---|---|---|---|
| Production API host | `https://api.pao.com.bd` | placeholder | `Frontend/apps/{customer,partner,admin}/config/prod.json` (`PAO_API_BASE_URL`); DNS |
| Staging API host | `https://api.staging.pao.com.bd` | placeholder | `Frontend/apps/*/config/staging.json` |
| Production admin web | `https://admin.pao.com.bd` | placeholder | Vercel domain; backend `ADMIN_CORS_ORIGIN` |
| Staging admin web | `https://admin-staging.pao.com.bd` | placeholder | Vercel alias; staging `ADMIN_CORS_ORIGIN` |
| Support phone | `09610000000` | placeholder | `Frontend/apps/{customer,partner}/config/*.json` (`PAO_SUPPORT_PHONE`) |
| Support email | `support@pao.com.bd` | placeholder | `Frontend/apps/customer/config/*.json` (`PAO_SUPPORT_EMAIL`) |
| First super admin | `owner@pao.com.bd`, "PAO Owner" | placeholder | the `migrate create-admin` command line ([deployment.md §3.5](deployment.md#35-first-deploy-order)) |
| App icons | Flutter defaults | placeholder | `Frontend/apps/{customer,partner}/android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset`; admin `web/icons`, `web/favicon.png` |
| App names | "PAO", "PAO Partner" | MVP default | Android `productFlavors`, iOS `APP_DISPLAY_NAME` ([release.md](release.md)) |
| Application / bundle IDs | `bd.pao.pao_customer`, `bd.pao.paoCustomer`, `bd.pao.pao_partner`, `bd.pao.paoPartner` | fixed once on a store | [deployment.md §4.2](deployment.md#42-flavours-and-app-ids) |
| Commission rate | 1000 bp (10%) | owner decision (ADR-0035) | admin setting `billing.commission_rate_bp`, 0–10000 |
| Due block amount | 50000 paisa (৳500) | owner decision (ADR-0035) | admin setting `billing.due_block_amount`, ≥ 0 |
| Load-test warm-up | 5 s at the test rate, reported, not judged | MVP rule | `Backend/Test/PAO.LoadTests` (`NearbySearch.WarmUp`) |
| Deploys | manual, by image digest | MVP rule | [`docs/runbooks/deploy.md`](../runbooks/deploy.md); image from the `backend-image` workflow |
| Store upload | manual | MVP rule | [deployment.md §4.7](deployment.md#47-upload) |
| Background jobs | in the API (`JOBS_IN_API=true`), no worker service, while on Render's free plan | MVP default (ADR-0036 §14) | the API's environment; on a paid plan add the worker and set `JOBS_IN_API=false` ([deployment.md §3.4.1](deployment.md#341-one-service-only-background-jobs-in-the-api-render-free-plan)) |

To replace the icons, put a 1024×1024 PNG per app in place and regenerate the sizes
(for example with `flutter_launcher_icons`, run once and commit the output; it is not a
build dependency).

## Firebase (Android push, MVP)

The Firebase client values are committed in `Frontend/apps/customer/config/prod.json` and
`Frontend/apps/partner/config/prod.json`: project `pao-notification`, sender
`474216579948`, the shared API key and one Android App ID per app. They are public by
design (every APK contains them), so `tools/build-release.sh <app> prod` builds with push
without exporting anything. An exported `PAO_FCM_*` variable still wins over the file.
iOS is not set up: an iOS build reuses the Android App ID and push will not work there
until an iOS app is added in Firebase and `PAO_FCM_APP_ID_<APP>_IOS` is set.
The backend's service-account key is a secret and stays out of the repository
(`FCM_CREDENTIALS_JSON` on the host).
