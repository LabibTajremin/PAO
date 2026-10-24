# Release builds

How the three apps are built, signed, versioned and submitted. Signing keys and
certificates belong to the owner: they live in CI secrets (or a release machine's
keychain) and are never committed. `key.properties`, `*.jks` and `*.keystore` are
git-ignored.

## Flavours

| Flavour | API (`config/<flavour>.json`) | Android application ID | iOS bundle ID | App name |
|---|---|---|---|---|
| dev | local stack (`10.0.2.2:8080` from the Android emulator) | `bd.pao.pao_customer.dev` / `bd.pao.pao_partner.dev` | `bd.pao.paoCustomer.dev` / `bd.pao.paoPartner.dev` | PAO Dev / PAO Partner Dev |
| staging | `https://api.staging.pao.com.bd` | `….staging` | `….staging` | PAO Staging / PAO Partner Staging |
| prod | `https://api.pao.com.bd` | `bd.pao.pao_customer` / `bd.pao.pao_partner` | `bd.pao.paoCustomer` / `bd.pao.paoPartner` | PAO / PAO Partner |

- Android: `productFlavors` in `android/app/build.gradle.kts` (dimension `environment`).
- iOS: schemes `dev`, `staging`, `prod` with build configurations `Debug-<flavour>`,
  `Release-<flavour>` and `Profile-<flavour>`; each sets `PRODUCT_BUNDLE_IDENTIFIER` and
  `APP_DISPLAY_NAME` (shown through `CFBundleDisplayName`). The plain `Debug`/`Release`
  configurations remain and build the prod identity.
- Dart: `Frontend/apps/<app>/config/<flavour>.json` holds non-secret
  `--dart-define` values only (`PAO_FLAVOUR`, `PAO_API_BASE_URL`, `PAO_SUPPORT_PHONE`,
  `PAO_SUPPORT_EMAIL`). `flutter run` defaults to `dev` (`default-flavor` in the
  pubspec); pass `--dart-define-from-file=config/dev.json` too.
- The staging and prod hostnames and the support contacts are placeholders until the
  owner confirms them. Application IDs cannot change once an app is on a store.

## Building

```sh
tools/build-release.sh customer prod            # app bundle (.aab)
tools/build-release.sh partner staging apk      # APK for testers
tools/build-release.sh customer prod ipa        # iOS archive (macOS + Xcode)
tools/build-release.sh admin prod               # admin web → Frontend/apps/admin/build/web
tools/build-release.sh partner dev linux        # desktop smoke build (no SDK needed)
```

Mobile release builds are obfuscated; the symbol files land in
`build/symbols/<flavour>` and must be kept per release to read crash stack traces
(`flutter symbolize`). Keys that must stay out of the repo are passed from the
environment when set: `PAO_MAPS_API_KEY`, `PAO_FCM_API_KEY`, `PAO_FCM_APP_ID`,
`PAO_FCM_SENDER_ID`, `PAO_FCM_PROJECT_ID`.

CI (`.github/workflows/frontend.yml`) builds the admin web bundle, an app bundle and
an APK for every app × flavour (`android` job), and the prod iOS archive for both apps
(`ios` job, macOS runner). Artifacts include the symbols.

## Versioning

- `version: x.y.z+n` in each app's `pubspec.yaml` is the source of truth: `x.y.z` is the
  marketing version (semantic: minor for features, patch for fixes), `n` the build
  number.
- CI overrides the build number with `PAO_BUILD_NUMBER` (the workflow run number), so
  every upload to Play and App Store Connect is strictly increasing.
- Dev and staging add `-dev`/`-staging` to the Android version name.
- Tag each store release `customer-vX.Y.Z` / `partner-vX.Y.Z` / `admin-vX.Y.Z` on the
  commit CI built, and keep the symbols artifact of that run.

## Signing

### Android (Play App Signing)

1. The owner creates an upload key once and keeps it offline with its passwords:
   `keytool -genkeypair -v -keystore upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload`.
2. Enrol each app in Play App Signing (Google holds the app-signing key; the upload key
   can be reset if lost).
3. Add repository secrets: `PAO_ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload.jks`),
   `PAO_ANDROID_KEYSTORE_PASSWORD`, `PAO_ANDROID_KEY_ALIAS`, `PAO_ANDROID_KEY_PASSWORD`.
   CI writes the keystore to the runner's temp folder and passes the path in
   `PAO_ANDROID_KEYSTORE`.
4. On a release machine instead: `Frontend/apps/<app>/android/key.properties` with
   `storeFile`, `storePassword`, `keyAlias`, `keyPassword` (git-ignored).

Without these, release builds are signed with the debug key so they can be installed
for testing; Play refuses them, and a push to `main` fails the `android` job instead of
producing one.

### iOS

1. In the Apple Developer account, register the bundle IDs from the table above, an
   Apple Distribution certificate and an App Store provisioning profile per app.
2. Add repository secrets: `PAO_IOS_CERT_P12_BASE64`, `PAO_IOS_CERT_PASSWORD`,
   `PAO_IOS_PROFILE_BASE64_customer`, `PAO_IOS_PROFILE_BASE64_partner`, and
   `PAO_IOS_EXPORT_OPTIONS_BASE64_customer`/`_partner` — an `ExportOptions.plist` with
   `method` `app-store-connect`, the `teamID` and the profile name per bundle ID.
3. CI imports them into a temporary keychain and runs `flutter build ipa
   --export-options-plist`. Without them it builds an unsigned archive
   (`--no-codesign`) that proves the prod scheme compiles.
4. Set `DEVELOPMENT_TEAM` in Xcode once the team is known (it is not secret).

### Firebase and Maps

`PAO_FCM_*` and `PAO_MAPS_API_KEY` are repository secrets per environment. Restrict the
Maps key to the Geocoding API and to the apps' package names / bundle IDs and SHA-256
signing certificates (Play's app-signing certificate for prod).

## Admin web

`tools/build-release.sh admin <flavour>` runs `flutter build web --release --csp
--no-web-resources-cdn --no-source-maps --base-href=${PAO_WEB_BASE_HREF:-/}`. `--csp`
keeps the compiled output free of eval-style code and CanvasKit is served from the
site, so the host can send a strict policy. Serve `build/web` from the admin origin
(the one in the backend's `ADMIN_CORS_ORIGIN`) with:

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval';
  style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https://<storage host>;
  font-src 'self'; connect-src 'self' https://api.pao.com.bd https://<storage host>;
  frame-ancestors 'none'; base-uri 'self'; form-action 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-cache            (index.html, flutter_bootstrap.js)
```

`'wasm-unsafe-eval'` is needed by CanvasKit; `'unsafe-inline'` styles by the Flutter
engine. `<storage host>` is the S3 public endpoint that signed document URLs point to.
Set `PAO_WEB_BASE_HREF=/admin/` when the panel is served under a path.

## What has and has not been run

- Run in the build container: `flutter build web` for the admin (prod) and `flutter build
  linux` for customer (prod) and partner (staging) through `build-release.sh`; Dart
  analysis and tests, including the partner presence-service channel.
- Not run here (no Android SDK or Xcode): the Gradle flavour builds, the Kotlin
  `PresenceService`, the iOS schemes and both signing paths. They run first in the
  `android` and `ios` CI jobs; check those runs before the first store upload.

## Store checklist

Before the first submission of each mobile app:

- [ ] Final application ID / bundle ID confirmed (table above); app names and icons
      (the launcher icons are still Flutter's defaults).
- [ ] Upload key and iOS distribution secrets added to CI; a signed prod build from
      `main` installs on a real device.
- [ ] Production `config/prod.json` values confirmed: API host, support phone and email.
- [ ] FCM project and `PAO_FCM_*` secrets; the backend runs `PUSH_ADAPTER=fcm`.
- [ ] Maps key restricted and set (customer app).
- [ ] Privacy policy URL (public web page) and terms; the in-app legal text has passed
      legal review (ADR-0029).
- [ ] Play Data safety form and App Store privacy labels: phone number, name, precise
      location (partner: while online only; customer: once, for the address), photos
      and identity documents (partner), crash data once Sentry is enabled.
- [ ] Play foreground-service declaration for `FOREGROUND_SERVICE_LOCATION` (partner),
      with a short video of going online and the ongoing notification.
- [ ] Location, camera and photo permission texts reviewed in Bangla and English
      (`Info.plist`, Android rationale).
- [ ] Test accounts for store review: a customer and an approved provider on the prod
      stack, with OTP delivery the reviewer can use.
- [ ] Screenshots per store size, short and full descriptions in Bangla and English,
      content rating questionnaire, target audience 18+ (partner).
- [ ] Release notes, version bumped in `pubspec.yaml`, git tag pushed, symbols kept.
- [ ] Staged rollout (Play: 10% → 50% → 100%; App Store: phased release) with crash
      and error dashboards watched between steps.
