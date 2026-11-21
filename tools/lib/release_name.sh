# shellcheck shell=bash
# release_name.sh — file names of mobile release builds (docs/guides/release.md).
# Sourced by tools/build-release.sh and the CLI tests; no side effects.
#
# Flutter writes app-<flavour>-release.apk for both apps, so two downloads of
# different apps look the same. Every release file carries the app, the flavour
# and the version instead.

# release_version <pubspec.yaml> [build number] — x.y.z-n, the build number
# from the argument when given, else from the pubspec.
release_version() {
  local line version build
  line="$(grep -m1 '^version:' "$1")" || return 1
  version="${line#version:}"
  version="${version// /}"
  build="${2:-${version#*+}}"
  [[ "$version" == *+* ]] || build="${2:-0}"
  printf '%s-%s\n' "${version%%+*}" "$build"
}

# release_name <app> <flavour> <version> <ext> — e.g. pao-partner-prod-1.2.0-45.apk
release_name() {
  printf 'pao-%s-%s-%s.%s\n' "$1" "$2" "$3" "$4"
}
