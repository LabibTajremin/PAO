# ADR-0022: Flag providers for review on rating and cancellation thresholds

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D13

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D13).

## Decision

A provider is flagged for review when their rating is below 3.5 after 10 jobs, or after more than 3 provider cancellations in 30 days (PRD §6.4).

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
