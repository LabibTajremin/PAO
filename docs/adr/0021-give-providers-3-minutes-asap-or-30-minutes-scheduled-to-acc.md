# ADR-0021: Give providers 3 minutes (ASAP) or 30 minutes (scheduled) to accept

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D12

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D12).

## Decision

Accept limits are 3 minutes for ASAP and 30 minutes for scheduled bookings; both are admin settings (PRD §5).

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
