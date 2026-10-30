# shellcheck shell=bash
# Finishing a phase: full gate, push with retry, open the pull request.

cmd_phase() {
  [[ "${1:-}" == "finish" && -n "${2:-}" ]] || die "usage: pao phase finish <id>"
  local id="$2" branch
  branch=$(git -C "$PAO_ROOT" rev-parse --abbrev-ref HEAD)
  cmd_ci
  PAO_SKIP_HOOK=1 retry git -C "$PAO_ROOT" push -u origin "$branch" || die "push failed"
  require_tool gh "https://cli.github.com"
  gh pr create --base main --head "$branch" --title "$id: $(phase_title "$id")" \
    --body-file <(phase_pr_body "$id") || die "could not open the PR"
}

phase_file() { find "$PAO_ROOT/docs/build/phases" -name "$1-*.md" -print -quit; }

phase_title() { head -1 "$(phase_file "$1")" | sed 's/^# [^ ]* — //'; }

phase_pr_body() {
  local file
  file=$(phase_file "$1")
  sed -n 's/^\*\*Goal:\*\* //p' "$file"
  printf '\n## Tasks\n\n'
  grep -E '^[0-9]+\. \*\*' "$file" | sed -E 's/^[0-9]+\. \*\*([^*]+)\*\*.*/- [x] \1/'
  printf '\n## Coverage\n\n'
  cat "$COVERAGE_DIR/summary.md" 2>/dev/null || true
}
