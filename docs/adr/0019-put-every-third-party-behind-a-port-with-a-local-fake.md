# ADR-0019: Put every third party behind a port with a local fake

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D10

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D10).

## Decision

SMS: `SmsSender` with `console` (dev) and `sslwireless` (prod). NID: `NidVerifier` with a `manual` adapter. Maps: Google Maps. Push: FCM with a `log` adapter in dev.

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
