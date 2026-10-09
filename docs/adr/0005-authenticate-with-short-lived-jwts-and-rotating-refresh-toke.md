# ADR-0005: Authenticate with short-lived JWTs and rotating refresh tokens in Redis

- Status: Accepted
- Date: 2026-10-09
- Source: PRD §9.6, §11; 04-decisions.md E5

## Context

Mobile users sign in by OTP; admins by password plus TOTP. Tokens must be revocable on logout, ban and role change.

## Decision

EdDSA access JWTs (15 min, `kid` rotation) plus opaque 256-bit refresh tokens stored hashed in a Redis token family. Each refresh rotates the token; reuse of an old one revokes the family. A Redis `jti` denylist covers live access tokens. Details in `docs/build/02-architecture.md` §5.

## Consequences

Stateless request authentication with immediate revocation; Redis becomes required (owner decision).
