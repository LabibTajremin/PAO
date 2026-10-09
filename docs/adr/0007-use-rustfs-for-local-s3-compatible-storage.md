# ADR-0007: Use RustFS for local S3-compatible storage

- Status: Accepted
- Date: 2026-10-09
- Source: P00 bootstrap

## Context

The build docs name MinIO for local object storage, but MinIO no longer publishes usable container images (`minio/minio` pulls fail).

## Decision

The Docker stack and CI use `rustfs/rustfs:1.0.1`, an Apache-2.0, S3-compatible server. The compose service keeps the name `minio` and the code only talks to the generic S3 API through the `storage` port, so production can use any S3 provider.

## Consequences

No code depends on the storage vendor. If RustFS proves unsuitable, any S3-compatible image can replace it by editing `docker-compose.yml` and the CI service.
