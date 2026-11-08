#!/usr/bin/env bash
# vercel-build.sh — the build command of the admin web on Vercel (docs/guides/deployment.md §2).
#
# Vercel's build image has no Flutter, so this fetches the version CI uses, builds the prod
# admin web with tools/build-release.sh and leaves it in Frontend/apps/admin/build/web, the
# project's output directory. Frontend/apps/admin/vercel.json names this script.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(sed -nE 's/^ *flutter-version: *([0-9.]+).*/\1/p' "$root/.github/workflows/frontend.yml" | head -1)"
flutter_home="${PAO_FLUTTER_HOME:-$HOME/flutter-$version}"

if [[ ! -x "$flutter_home/bin/flutter" ]]; then
  # A shallow clone of the release tag is far smaller than the 1.5 GB SDK archive; the
  # engine artifacts it needs for web then come from Google's storage on first use.
  git clone --quiet --depth 1 --branch "$version" https://github.com/flutter/flutter.git "$flutter_home"
fi
export PATH="$flutter_home/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true CI=true

flutter --version
(cd "$root/Frontend" && flutter pub get)
"$root/tools/build-release.sh" admin "${PAO_ADMIN_FLAVOUR:-prod}" web
