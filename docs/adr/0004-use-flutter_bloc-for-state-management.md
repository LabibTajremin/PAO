# ADR-0004: Use flutter_bloc for state management

- Status: Accepted
- Date: 2026-10-09
- Source: PRD §9.5; 04-decisions.md E4

## Context

The PRD asks for one state-management library across all apps, decided once.

## Decision

All three Flutter apps use `flutter_bloc` (Cubits by default, Blocs where events matter). Widgets never call repositories directly.

## Consequences

Predictable, testable state with `bloc_test`; a little more boilerplate than lighter options.
