# API

The contract is `Backend/Api/openapi.yaml` (121 operations), bundled into
`PAO.Core/Spec/openapi.gen.yaml` by `scripts/gen-spec.sh` (`--check` fails on drift). The
edge matches every request to an operation of the bundle ([HTTP edge](../Architecture/http-edge.md)).

## Platform controllers

| Controller | Routes | Attribute |
|---|---|---|
| `UnimplementedController` | every spec operation no area serves yet | `[PermissionFromSpec]`; answers 501 `NOT_IMPLEMENTED` after authentication, permission, rate-limit and validation checks |

Health routes (`/healthz`, `/readyz`) are minimal endpoints outside the contract.
Area controllers are listed in each area's `endpoints.md` ([areas](../Areas/README.md)).

## Errors

`{"error":{"code","message","details?"}}` (PRD §9.6). Platform codes: `UNAUTHENTICATED`,
`TOKEN_EXPIRED`, `FORBIDDEN` (with `details.permission`), `NOT_FOUND` (404 and 405),
`VALIDATION_FAILED` (`details.reason`), `RATE_LIMITED` (with `Retry-After`),
`IDEMPOTENCY_KEY_REUSED`, `CONFLICT`, `INTERNAL`, `NOT_IMPLEMENTED`.
