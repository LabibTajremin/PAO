# platform/http — the HTTP edge

Every request passes the same pipeline. `api/openapi.yaml` (bundled into
`openapi.gen.yaml`) is the contract; the edge enforces it before a controller runs.

## Pipeline order

| Step | Nest building block                        | What it does                                                                                                                                                                               |
| ---- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1    | middleware                                 | client IP (X-Forwarded-For trusted only from private networks), request id + logging context, security headers, CORS for `ADMIN_CORS_ORIGIN`, body reader (1 MB, JSON), cookies, metrics   |
| 2    | middleware `SpecMatchMiddleware`           | matches the request to an OpenAPI operation: unknown path → 404 `NOT_FOUND`, wrong method → 405; health routes are allowed outside the contract                                            |
| 3    | guard `AuthenticationGuard`                | bearer EdDSA token + denylist; `TOKEN_EXPIRED` on expiry, `UNAUTHENTICATED` otherwise; skipped for `@Public()`                                                                             |
| 4    | guard `AuthorizationGuard`                 | the route's permission decorator against the caller's roles (RBAC cache); no decorator → 403                                                                                               |
| 5    | guard `RateLimitGuard`                     | 120/min per user, 60/min per IP, per operation (`rl:api:{subject}:{operationId}`) → 429 + `Retry-After`                                                                                    |
| 6    | interceptor `RequestValidationInterceptor` | Ajv (JSON Schema 2020-12) against the operation: path, query, header, cookie and body → 422 `VALIDATION_FAILED` with `details.reason`; replaces `req.query`/`req.params` with typed values |
| 7    | interceptor `IdempotencyInterceptor`       | operations with an `Idempotency-Key` header: replays the first answer for 24 h, 422 `IDEMPOTENCY_KEY_REUSED`, 409 while running                                                            |
| 8    | interceptor `@MapErrors(map)`              | per controller: `DomainError` reasons → `ApiError`                                                                                                                                         |
| 9    | filter `ErrorFilter`                       | the one error envelope `{"error":{"code","message","details?"}}`; anything unexpected is logged and answered 500 `INTERNAL`                                                                |

Validation is an interceptor, not a pipe: a pipe sees one handler argument at a time and
never the matched operation. Because it runs before the idempotency interceptor, an
invalid request never claims an idempotency key, and 401/403 always come before 422.

Operations no module serves yet are answered 501 `NOT_IMPLEMENTED` by the catch-all in
`unimplemented.module.ts`, after the same checks (its permission is the operation's
`x-permission`). The composition root imports it last.

## Permissions on routes

Every controller method declares who may call it; a route without a decorator is denied.

```ts
@Controller('v1/customer/bookings')
@MapErrors(bookingErrors)
export class CustomerBookingsController {
  @Post()
  @RequirePermission('booking:create')
  @HttpCode(201)
  create(@CurrentPrincipal() me: Principal, @Body() body: CreateBookingRequest) { ... }
}
```

- `@RequirePermission('booking:create')` — the caller's roles must grant it.
- `@Authenticated()` — any signed-in account.
- `@Public()` — no token.

The decorator must equal the operation's `x-permission`. Check it in your module's
integration spec:

```ts
const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
expect(report.mismatched).toEqual([]);
expect(report.undocumented).toEqual([]);
expect(report.unserved.filter((op) => op.includes('/v1/customer/bookings'))).toEqual([]);
```

`:own` permissions only say the caller may act on their own resources; the use case
still compares `principal.accountId` with the owner.

`@CurrentPrincipal()` gives `{ accountId, roles, tokenId, sessionId, expiresAt }`;
`@ClientIp()` gives the caller's address. Lists use `decodeCursor`/`encodeCursor` and
`pageSize` from `cursor.ts`.
