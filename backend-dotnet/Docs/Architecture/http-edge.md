# HTTP edge

Every API request passes, in the NestJS order:

1. `ErrorEnvelopeMiddleware` — anything that escapes becomes the PRD §9.6 envelope.
2. Test hooks (`/__test/*`, only with `APP_ENV=test`).
3. `EdgeMiddleware`: client IP (X-Forwarded-For only from private peers), `X-Request-ID`,
   security headers, CORS for the admin origin, body read once (1 MB limit, JSON parsed).
4. `PaoMetrics.Record` — `pao_http_requests_total`, `pao_http_request_duration_seconds`.
5. `SpecMatchMiddleware` — matches the bundled `Spec/openapi.gen.yaml`; unknown path 404,
   wrong method 405 (code `NOT_FOUND`), before any controller.
6. MVC filters: `AccessFilter` (JWT, denylist, RBAC) → `RateLimitFilter` (120/min per user,
   60/min per IP, per operation) → `RequestValidationFilter` → `IdempotencyFilter`.
7. The controller; `ApiExceptionFilter` maps domain errors with the area's `[ErrorMap]`
   and writes the envelope.

## Validation choice

Requests are validated against the OpenAPI spec (`RequestValidator` with the in-house
`SchemaValidator` for the keywords the contract uses), not by hand-written validators per
endpoint. It keeps one source of truth with the Flutter client, validates operations no
area serves yet, and reproduces NestJS behaviour: 422 `VALIDATION_FAILED` with
`details.reason` in Ajv's wording (`body/phone must match pattern "…"`). FluentValidation
runs in the mediator pipeline for business rules the schema cannot express.

## Idempotency

Operations declaring `Idempotency-Key` store their first answer below 500 for 24 hours under
`idem:{userId}:{key}`, in the record format NestJS wrote, and replay it with
`Idempotent-Replayed: true`. A different body under the same key is 422
`IDEMPOTENCY_KEY_REUSED`; a request still running is 409 `CONFLICT`.
