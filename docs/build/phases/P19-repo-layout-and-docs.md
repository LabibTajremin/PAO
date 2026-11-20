# P19 — Repository layout, project files and human docs

**Goal:** a developer who clones the repo can open it in Visual Studio or VS Code in one
step, find any piece of code within a minute, and read docs that sound like a colleague
wrote them.

**Read first:** `06-update-2026-11.md` items v and xiv; E15 in `04-decisions.md`; ADR-0034
"Repository layout after cut-over"; `Backend/scripts/ci.sh`, `tools/pao`, `.github/workflows/`.

## Rules

- Moves only, with `git mv`, so history follows. No behaviour change in this phase.
- Do not rename C# projects or namespaces; group them.
- Update every path that points into a moved folder: CI workflows, `tools/`, `infra/`,
  Dockerfiles, coverage config, `CLAUDE.md`, docs. `rg` the old path until nothing is left.

## Target layout

```
PAO.sln                    the only solution: all C# projects, in solution folders src / tests / tools
PAO.code-workspace         VS Code: folders Backend, Frontend, docs, infra, tools, design
.vscode/                   extensions.json, launch.json (API, Worker, Migrator, each Flutter app), tasks.json (./pao up, ./pao ci)
README.md                  what PAO is, quick start in 5 commands, map of the folders
Backend/
  README.md                how the backend is built and run, where each kind of code lives
  src/                     PAO.Core, PAO.Lib, PAO.EF, PAO.Infrastructure, PAO.BackgroundJobs, PAO.Worker, PAO.Migrator
  tests/                   PAO.UnitTests, PAO.IntegrationTests, PAO.E2ETests, PAO.LoadTests, PAO.TestKit
  tools/                   PAO.Gates
  api/                     OpenAPI contract (was Api/)
  config/                  per-concern JSON (was Config/) + appsettings.Local.example.json
  database/                SQL changes (was "DB Changes/") and seed data (was Seed/)
  docs/                    area docs (was Docs/) + the rules from PAO.AI/README.md as conventions.md
  scripts/
  Directory.Build.props, Directory.Packages.props, global.json, .editorconfig, coverage.config
Frontend/
  README.md
  apps/  packages/  e2e/ (was test/e2e)
  pubspec.yaml, analysis_options.yaml
design/                    brand assets, illustrations, references
docs/  infra/  tools/
```

`Backend/Logs/` is removed from git and ignored (logs are written outside the repo). Remove
the empty `PAO.AI` folder after moving its README. Unignore `.vscode/` except
`.vscode/settings.local.json`.

## Docs

- One README per top folder and per project: what it is, how to run or test it, the three files
  to open first. Short, second person, concrete commands.
- `docs/README.md` indexes everything; `docs/guides/getting-started.md` goes from clone to a
  running app on an emulator.
- Tone: like an experienced teammate. No "This document provides", no "Step 1:" narration, no
  emoji, no filler. Explain *why* where it isn't obvious.

## Definition of done

`dotnet build PAO.sln` from the root works; Visual Studio 2022 and VS Code (C# Dev Kit +
Flutter extensions) open the repo and run the API and each app from the run menu. No file sits
loose at `Backend/` or `Frontend/` root other than those listed. `./pao ci` green.
