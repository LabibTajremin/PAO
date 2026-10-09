# ADR-0018: Build the admin panel with Flutter Web

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D9

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D9).

## Decision

The admin panel is Flutter Web (`frontend/apps/admin`), sharing `pao_core`, `pao_ui` and `pao_api`.

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
