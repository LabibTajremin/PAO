# ADR-0020: Serve home salon with women providers only

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D11

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D11).

## Decision

Home salon is served only by women providers (`provider.gender = female`, service flag `women_providers_only`). Customers cannot pick provider gender for other services in the MVP.

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
