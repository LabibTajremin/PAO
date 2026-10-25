# HTTP edge

Every API request passes, in this order (kept so existing clients see the same answers):

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

## Request bodies: read after authorisation

The API authenticates and authorises before it looks at the body, so a request without a
token gets 401, and one without the permission gets 403, whatever its body. ASP.NET binds
action parameters *before* action filters run, and its `[FromBody]` binder answers 415
(wrong or missing content type) or 400 there, ahead of `AccessFilter`.

The edge closes that gap once for every controller: `EdgeBodyBinderProvider`
(`PAO.Infrastructure/Http/Edge/EdgeBodyBinder.cs`), registered first in `AddHttpEdge`,
serves every `BindingSource.Body` parameter. `EdgeBodyBinder` reads the JSON that
`EdgeMiddleware.ReadBody` already parsed into `EdgeState.Body` and never fails: a missing
body, or one of the wrong shape, binds as the empty model. Nothing is reported at binding
time, so the order is access (401/403) → rate limit → `RequestValidationFilter`, which
answers 422 from the spec for a missing, malformed or invalid body → idempotency → action.
The action never runs with that empty model.

Controllers write plain `[FromBody] SomeInput body` parameters. Never read
`Request.Body` or `EdgeState.Body` by hand in a controller.

## Validation choice

Requests are validated against the OpenAPI spec (`RequestValidator` with the in-house
`SchemaValidator` for the keywords the contract uses), not by hand-written validators per
endpoint. It keeps one source of truth with the Flutter client, validates operations no
area serves yet, and keeps the established behaviour: 422 `VALIDATION_FAILED` with
`details.reason` in Ajv's wording (`body/phone must match pattern "…"`). FluentValidation
runs in the mediator pipeline for business rules the schema cannot express.

## Idempotency

Operations declaring `Idempotency-Key` store their first answer below 500 for 24 hours under
`idem:{userId}:{key}`, in the record format earlier releases wrote, and replay it with
`Idempotent-Replayed: true`. A different body under the same key is 422
`IDEMPOTENCY_KEY_REUSED`; a request still running is 409 `CONFLICT`.
