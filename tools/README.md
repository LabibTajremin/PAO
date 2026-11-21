# tools

The scripts behind `./pao` and the release builds.

| Path | What it is |
|---|---|
| `pao`, `lib/` | The `pao` command (`./pao help` lists everything). Each `lib/*.sh` file is one group of commands |
| `hooks/` | Git hooks `./pao setup` installs: fast checks before a commit, Conventional Commit messages |
| `cli/` | Tests for the `pao` command itself (`bats tools/cli/pao_test.bats`) |
| `build-release.sh` | Release builds of the apps: `tools/build-release.sh customer prod apk` |
| `gen-dart-client.sh` | Regenerates `Frontend/packages/pao_api` from the API contract |
| `vercel-build.sh` | How Vercel builds the admin web |
| `ops/`, `fixtures/` | Helpers for the ops checks and the CLI tests |
| `autopilot.sh` | Keeps an unattended build run going across usage limits (see `.claude/skills/automatic-agentic-run`) |
