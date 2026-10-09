# ADR-0001: Build the backend as a modular monolith

- Status: Accepted
- Date: 2026-10-09
- Source: PRD §9, 04-decisions.md E1

## Context

PAO must ship quickly with a small team yet be able to split into services later (PRD §9).

## Decision

One Go binary with eleven modules (`identity`, `customer`, `provider`, `verification`, `catalog`, `booking`, `rating`, `notification`, `media`, `admin`, `audit`). Each module exposes only `contract/`, owns one Postgres schema, and communicates through contracts and outbox events. `go-arch-lint` enforces the boundaries in CI.

## Consequences

Simple deployment and refactoring today. Extracting a module means moving its folder and replacing its in-process contract adapter with a network client; no caller changes.
