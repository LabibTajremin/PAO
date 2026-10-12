# shellcheck shell=bash
# Dependency and secret scanning (docs/build/02-architecture.md §7).

# audit_npm fails on a high or critical advisory in a package's runtime dependencies.
audit_npm() {
  [[ -f "$1/package-lock.json" ]] || return 0
  (cd "$1" && npm audit --omit=dev --audit-level=high >/dev/null) ||
    die "npm audit found vulnerable packages in ${1#"$PAO_ROOT"/} (run npm audit there)"
}

cmd_security() {
  require_tool gitleaks "https://github.com/gitleaks/gitleaks (v8.21+)"
  gitleaks git --no-banner --redact "$PAO_ROOT" >/dev/null || die "gitleaks found a secret"
  require_tool npm "https://nodejs.org (22.12+)"
  audit_npm "$BACKEND"
  audit_npm "$E2E_API"
  if [[ -f "$FRONTEND/pubspec.lock" ]]; then
    require_tool osv-scanner "https://google.github.io/osv-scanner/installation/"
    osv-scanner scan source --lockfile "$FRONTEND/pubspec.lock" >/dev/null ||
      die "osv-scanner found vulnerable Dart packages"
  fi
  if [[ -n "${PAO_SCAN_IMAGE:-}" ]]; then
    require_tool trivy "https://trivy.dev/latest/getting-started/installation/"
    trivy image --quiet --exit-code 1 --severity HIGH,CRITICAL "$PAO_SCAN_IMAGE" ||
      die "trivy found high or critical issues in $PAO_SCAN_IMAGE"
  fi
  ok "security scans clean"
}
