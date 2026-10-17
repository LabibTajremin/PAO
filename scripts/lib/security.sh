# shellcheck shell=bash
# Dependency, image and secret scanning (docs/build/02-architecture.md §7,
# docs/security-checklist.md). Accepted findings live in osv-scanner.toml and
# .trivyignore at the repository root, each with its reason.

# Trivy runs from its pinned image, so laptops and CI scan with the same version.
TRIVY_IMAGE="${PAO_TRIVY_IMAGE:-mirror.gcr.io/aquasec/trivy:0.64.1}"

# audit_npm fails on a high or critical advisory in a package's runtime dependencies.
audit_npm() {
  [[ -f "$1/package-lock.json" ]] || return 0
  (cd "$1" && npm audit --omit=dev --audit-level=high >/dev/null) ||
    die "npm audit found vulnerable packages in ${1#"$PAO_ROOT"/} (run npm audit there)"
}

# scan_lockfiles checks every lockfile (Dart and npm, dev tools included) against OSV.
scan_lockfiles() {
  require_tool osv-scanner "https://google.github.io/osv-scanner/installation/ (v2.2+)"
  local args=(--config "$PAO_ROOT/osv-scanner.toml")
  local lock
  for lock in "$FRONTEND/pubspec.lock" "$BACKEND/package-lock.json" "$E2E_API/package-lock.json"; do
    [[ -f "$lock" ]] && args+=(--lockfile "$lock")
  done
  osv-scanner scan source "${args[@]}" >/dev/null ||
    die "osv-scanner found vulnerable packages (run: osv-scanner scan source ${args[*]})"
}

# trivy_run runs the pinned trivy image with the repository mounted read-only and a
# cache volume; an extra CA bundle (PAO_EXTRA_CA_FILE) is trusted when set.
trivy_run() {
  local opts=(--rm -v "$PAO_ROOT:/src:ro" -v pao-trivy-cache:/root/.cache
    -v /var/run/docker.sock:/var/run/docker.sock)
  if [[ -n "${PAO_EXTRA_CA_FILE:-}" ]]; then
    opts+=(-v "$PAO_EXTRA_CA_FILE:/extra-ca.crt:ro" -e SSL_CERT_FILE=/extra-ca.crt
      --network host -e HTTPS_PROXY -e HTTP_PROXY -e NO_PROXY)
  fi
  docker run "${opts[@]}" "$TRIVY_IMAGE" "$@"
}

# scan_trivy checks the source tree (vulnerabilities, secrets, misconfigurations) and,
# when PAO_SCAN_IMAGE names one, the built backend image.
scan_trivy() {
  require_tool docker "https://docs.docker.com/get-docker/"
  local common=(--quiet --exit-code 1 --severity "HIGH,CRITICAL" --ignorefile /src/.trivyignore)
  trivy_run fs "${common[@]}" --scanners vuln,secret,misconfig \
    --skip-dirs /src/backend/node_modules --skip-dirs /src/test/e2e/api/node_modules \
    --skip-dirs /src/frontend/.dart_tool --skip-dirs '/src/frontend/apps/*/build' /src >/dev/null ||
    die "trivy found high or critical issues in the source tree (rerun without >/dev/null)"
  if [[ -n "${PAO_SCAN_IMAGE:-}" ]]; then
    trivy_run image "${common[@]}" --scanners vuln,secret "$PAO_SCAN_IMAGE" >/dev/null ||
      die "trivy found high or critical issues in $PAO_SCAN_IMAGE"
  fi
}

# scan_bundles feeds the printable strings of every built app bundle (web, Linux, Android)
# to gitleaks, so a secret compiled in with --dart-define is caught (MASVS-STORAGE).
scan_bundles() {
  local dirs=() d
  # The Linux bundle only: build/linux also holds CMake caches full of "secret" words.
  for d in "$FRONTEND"/apps/*/build/{web,app/outputs,linux/*/release/bundle}; do
    [[ -d "$d" ]] && dirs+=("$d")
  done
  ((${#dirs[@]})) || return 0
  require_tool strings "binutils"
  find "${dirs[@]}" -type f -print0 | xargs -0 strings -n 8 |
    gitleaks stdin --no-banner --redact >/dev/null 2>&1 ||
    die "gitleaks found a secret in a built app bundle (${dirs[*]#"$PAO_ROOT"/})"
}

cmd_security() {
  require_tool gitleaks "https://github.com/gitleaks/gitleaks (v8.21+)"
  gitleaks git --no-banner --redact "$PAO_ROOT" >/dev/null || die "gitleaks found a secret"
  scan_bundles
  require_tool npm "https://nodejs.org (22.12+)"
  audit_npm "$BACKEND"
  audit_npm "$E2E_API"
  scan_lockfiles
  scan_trivy
  ok "security scans clean"
}
