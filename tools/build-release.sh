#!/usr/bin/env bash
# build-release.sh — one release build of one app for one flavour (docs/guides/release.md).
#
#   tools/build-release.sh <customer|partner|admin> <dev|staging|prod> [target]
#
# target: appbundle (default for the mobile apps), apk, ipa, linux, web (admin only).
# Non-secret settings come from Frontend/apps/<app>/config/<flavour>.json; keys that
# must stay out of the repo are read from the environment when set:
#   PAO_MAPS_API_KEY, PAO_FCM_API_KEY, PAO_FCM_APP_ID, PAO_FCM_SENDER_ID,
#   PAO_FCM_PROJECT_ID, PAO_PIN_SHA256, PAO_SENTRY_DSN, PAO_BUILD_NUMBER,
#   PAO_WEB_BASE_HREF, PAO_IOS_EXPORT_OPTIONS.
# Firebase issues one App ID per platform and app, so PAO_FCM_APP_ID_<APP>_<ANDROID|IOS>
# (e.g. PAO_FCM_APP_ID_CUSTOMER_IOS) wins over PAO_FCM_APP_ID when set (ADR-0036).
# An unset or empty value leaves its feature off: no push, no pinning, no Sentry.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app="${1:-}" flavour="${2:-}"
case "$app" in customer | partner | admin) ;; *) echo "usage: $0 <customer|partner|admin> <dev|staging|prod> [target]" >&2 && exit 2 ;; esac
case "$flavour" in dev | staging | prod) ;; *) echo "unknown flavour: $flavour" >&2 && exit 2 ;; esac
default_target=appbundle
[[ "$app" == admin ]] && default_target=web
target="${3:-$default_target}"

dir="$root/Frontend/apps/$app"
args=(--release "--dart-define-from-file=config/$flavour.json")
[[ -n "${PAO_BUILD_NUMBER:-}" ]] && args+=("--build-number=$PAO_BUILD_NUMBER")
platform=ANDROID
[[ "$target" == ipa ]] && platform=IOS
# macOS runners ship bash 3.2, which has no ${var^^}.
platform_app_id="PAO_FCM_APP_ID_$(printf %s "$app" | tr '[:lower:]' '[:upper:]')_${platform}"
for key in PAO_MAPS_API_KEY PAO_FCM_API_KEY PAO_FCM_APP_ID PAO_FCM_SENDER_ID PAO_FCM_PROJECT_ID PAO_PIN_SHA256 PAO_SENTRY_DSN; do
  value="${!key:-}"
  if [[ "$key" == PAO_FCM_APP_ID && -n "${!platform_app_id:-}" ]]; then value="${!platform_app_id}"; fi
  if [[ -n "$value" ]]; then args+=("--dart-define=$key=$value"); fi
done

case "$target" in
  web)
    [[ "$app" == admin ]] || { echo "only the admin app builds for web" >&2 && exit 2; }
    # --csp avoids eval-style code and the local CanvasKit avoids a third-party
    # script origin, so the panel runs under the strict policy in docs/guides/release.md.
    args+=(--csp --no-web-resources-cdn --no-source-maps "--base-href=${PAO_WEB_BASE_HREF:-/}")
    ;;
  appbundle | apk | ipa)
    [[ "$app" != admin ]] || { echo "the admin app builds for web only" >&2 && exit 2; }
    # Obfuscated release code; the symbols stay with CI to decode crash reports.
    args+=("--flavor=$flavour" --obfuscate "--split-debug-info=build/symbols/$flavour")
    if [[ "$target" == ipa ]]; then
      if [[ -n "${PAO_IOS_EXPORT_OPTIONS:-}" ]]; then
        args+=("--export-options-plist=$PAO_IOS_EXPORT_OPTIONS")
      else
        args+=(--no-codesign)
      fi
    fi
    ;;
  linux) args+=("--flavor=$flavour") ;;
  *) echo "unknown target: $target" >&2 && exit 2 ;;
esac

cd "$dir"
flutter build "$target" "${args[@]}"
