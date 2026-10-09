# shellcheck shell=bash
# Dependency and secret scanning (docs/build/02-architecture.md §7).

cmd_security() {
  require_tool gitleaks "go install github.com/zricethezav/gitleaks/v8@v8.21.2"
  gitleaks git --no-banner --redact "$PAO_ROOT" >/dev/null || die "gitleaks found a secret"
  if [[ -f "$BACKEND/go.mod" ]]; then
    require_tool govulncheck "go install golang.org/x/vuln/cmd/govulncheck@v1.8.0"
    (cd "$BACKEND" && govulncheck ./...) >/dev/null || die "govulncheck found vulnerabilities"
  fi
  if [[ -f "$FRONTEND/pubspec.lock" ]]; then
    require_tool osv-scanner "go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest"
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
