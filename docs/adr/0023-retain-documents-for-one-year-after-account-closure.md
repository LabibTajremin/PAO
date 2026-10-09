# ADR-0023: Retain documents for one year after account closure

- Status: Accepted (default — owner may revise)
- Date: 2026-10-09
- Source: PRD §13; docs/build/04-decisions.md D14

## Context

The PRD leaves this question open (§13). The build needs a default to stay autonomous (D14).

## Decision

Verification documents are kept while the account is active plus 1 year after closure (a setting), then purged by a job.

## Consequences

The owner may revise this default; changing it later means a new ADR that supersedes this one, not a silent edit.
