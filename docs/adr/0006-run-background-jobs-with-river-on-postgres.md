# ADR-0006: Run background jobs with River on Postgres

- Status: Superseded by ADR-0032 (in-process scheduler; River is Go-only)
- Date: 2026-10-09
- Source: 04-decisions.md E6

## Context

Booking timeouts, document expiry, reminders and the outbox relay need durable scheduled work.

## Decision

Use `riverqueue/river`, backed by the existing Postgres, in one `cmd/worker` binary shipped in the API image.

## Consequences

No extra queue infrastructure; jobs are transactional with module writes.
