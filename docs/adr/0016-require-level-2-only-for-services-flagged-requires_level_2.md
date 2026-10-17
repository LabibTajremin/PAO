# ADR-0016: Require Level 2 only for services flagged requires_level_2

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D7

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D7).

## Decision

Level 2 is required before the first booking only for services with `requires_level_2` set (none of the MVP five). Level 2 providers still rank higher.

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
