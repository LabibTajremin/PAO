# shellcheck shell=bash
# Dependency, image and secret scanning (docs/build/02-architecture.md §7,
# docs/guides/security-checklist.md). The scanners' configuration and accepted findings
# live in infra/security/ (gitleaks.toml, osv-scanner.toml, trivyignore), each with its reason.

SECURITY_DIR="$INFRA/security"

# Trivy runs from its pinned image, so laptops and CI scan with the same version.
TRIVY_IMAGE="${PAO_TRIVY_IMAGE:-mirror.gcr.io/aquasec/trivy:0.64.1}"

# scan_lockfiles checks every lockfile (Dart, and the NuGet packages.lock.json of each
# .NET project, test tools included) against OSV.
scan_lockfiles() {
  require_tool osv-scanner "https://google.github.io/osv-scanner/installation/ (v2.2+)"
  local args=(--config "$SECURITY_DIR/osv-scanner.toml")
  local lock
  while IFS= read -r lock; do
    args+=(--lockfile "$lock")
  done < <(find "$FRONTEND/pubspec.lock" "$BACKEND" \( -name pubspec.lock -o -name packages.lock.json \) \
    -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null | sort)
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
  local common=(--quiet --exit-code 1 --severity "HIGH,CRITICAL" --ignorefile /src/infra/security/trivyignore)
  trivy_run fs "${common[@]}" --scanners vuln,secret,misconfig \
    --skip-dirs /src/Frontend/.dart_tool --skip-dirs '/src/Frontend/apps/*/build' \
    --skip-dirs '/src/Backend/**/bin' --skip-dirs '/src/Backend/**/obj' --skip-dirs /src/out /src >/dev/null ||
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
    gitleaks stdin --no-banner --redact --config "$SECURITY_DIR/gitleaks.toml" >/dev/null 2>&1 ||
    die "gitleaks found a secret in a built app bundle (${dirs[*]#"$PAO_ROOT"/})"
}

cmd_security() {
  require_tool gitleaks "https://github.com/gitleaks/gitleaks (v8.21+)"
  gitleaks git --no-banner --redact --config "$SECURITY_DIR/gitleaks.toml" "$PAO_ROOT" >/dev/null ||
    die "gitleaks found a secret"
  scan_bundles
  scan_lockfiles
  scan_trivy
  ok "security scans clean"
}
