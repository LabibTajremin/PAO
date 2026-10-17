# ADR-0014: Launch in Dhaka with a 5 km default radius

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D5

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D5).

## Decision

Launch area is Dhaka. The default search radius is 5 km, configurable per service (PRD §5).

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
