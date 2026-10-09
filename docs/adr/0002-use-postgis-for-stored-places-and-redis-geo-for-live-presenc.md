# ADR-0002: Use PostGIS for stored places and Redis GEO for live presence

- Status: Accepted
- Date: 2026-10-09
- Source: PRD §9.1, §11; 04-decisions.md E2

## Context

Nearby search must answer in under 300 ms at p95 (PRD §11) and only show providers who are online now.

## Decision

Addresses and provider home bases are `geography(Point,4326)` columns with GiST indexes. Online providers are kept in a Redis GEO set per service, refreshed by heartbeats and pruned by the worker. Search reads the GEO set, then filters by verification and registration through contracts.

## Consequences

Fast radius queries; presence is rebuildable state, so losing Redis only takes providers offline until their next heartbeat.
