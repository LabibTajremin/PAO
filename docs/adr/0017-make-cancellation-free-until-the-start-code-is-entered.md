# ADR-0017: Make cancellation free until the start code is entered

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D8

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D8).

## Decision

Customers may cancel free of charge until the start code is entered (PRD §5). Providers may cancel after acceptance with a reason; it counts towards quality metrics (PRD §6.4). No fees in the MVP.

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
