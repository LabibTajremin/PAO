#!/usr/bin/env bash
# build-release.sh — one release build of one app for one flavour (docs/release.md).
#
#   scripts/build-release.sh <customer|partner|admin> <dev|staging|prod> [target]
#
# target: appbundle (default for the mobile apps), apk, ipa, linux, web (admin only).
# Non-secret settings come from frontend/apps/<app>/config/<flavour>.json; keys that
# must stay out of the repo are read from the environment when set:
#   PAO_MAPS_API_KEY, PAO_FCM_API_KEY, PAO_FCM_APP_ID, PAO_FCM_SENDER_ID,
#   PAO_FCM_PROJECT_ID, PAO_BUILD_NUMBER, PAO_WEB_BASE_HREF, PAO_IOS_EXPORT_OPTIONS.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app="${1:-}" flavour="${2:-}"
case "$app" in customer | partner | admin) ;; *) echo "usage: $0 <customer|partner|admin> <dev|staging|prod> [target]" >&2 && exit 2 ;; esac
case "$flavour" in dev | staging | prod) ;; *) echo "unknown flavour: $flavour" >&2 && exit 2 ;; esac
default_target=appbundle
[[ "$app" == admin ]] && default_target=web
target="${3:-$default_target}"

dir="$root/frontend/apps/$app"
args=(--release "--dart-define-from-file=config/$flavour.json")
[[ -n "${PAO_BUILD_NUMBER:-}" ]] && args+=("--build-number=$PAO_BUILD_NUMBER")
for key in PAO_MAPS_API_KEY PAO_FCM_API_KEY PAO_FCM_APP_ID PAO_FCM_SENDER_ID PAO_FCM_PROJECT_ID; do
  [[ -n "${!key:-}" ]] && args+=("--dart-define=$key=${!key}")
done

case "$target" in
  web)
    [[ "$app" == admin ]] || { echo "only the admin app builds for web" >&2 && exit 2; }
    # --csp avoids eval-style code and the local CanvasKit avoids a third-party
    # script origin, so the panel runs under the strict policy in docs/release.md.
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
