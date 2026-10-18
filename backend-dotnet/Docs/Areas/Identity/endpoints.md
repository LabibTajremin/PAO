# Identity area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
Every controller maps the area's reasons with `IdentityErrorMap`.

| Controller | Operation | Route | Attribute |
|---|---|---|---|
| `AuthController` | requestOtp | `POST /v1/auth/otp/request` (202) | `[AllowAnonymous]` |
| | verifyOtp | `POST /v1/auth/otp/verify` | `[AllowAnonymous]` |
| | refreshToken | `POST /v1/auth/refresh` (body token, or the `pao_refresh` cookie) | `[AllowAnonymous]` |
| | logout | `POST /v1/auth/logout` (204, clears the cookie) | `[AllUserType]` |
| `AdminAuthController` | adminLogin | `POST /v1/auth/admin/login` | `[AllowAnonymous]` |
| | adminVerifyTotp | `POST /v1/auth/admin/totp` (sets the cookie) | `[AllowAnonymous]` |
| | changeAdminPassword | `POST /v1/auth/admin/password` (204) | `[AllUserType]` |
| `MeController` | getMe | `GET /v1/me` | `[AllUserType]` |
| | getMyPermissions | `GET /v1/me/permissions` | `[AllUserType]` |
| | deleteMe | `DELETE /v1/me` (204) | `[AllUserType]` |
| `AdminUsersController` | listAdminUsers | `GET /v1/admin/admin-users` | `[Admin(Permission = "admin_user:manage")]` |
| | inviteAdminUser | `POST /v1/admin/admin-users` (201) | `[Admin(Permission = "admin_user:manage")]` |
| | updateAdminUser | `PATCH /v1/admin/admin-users/{adminUserId}` | `[Admin(Permission = "admin_user:manage")]` |
| `RolesController` (in `AdminUsersController.cs`) | listRoles | `GET /v1/admin/roles` | `[Admin(Permission = "role:manage")]` |
| | updateRole | `PUT /v1/admin/roles/{role}` | `[Admin(Permission = "role:manage")]` |

Error codes: `OTP_INVALID`, `OTP_EXPIRED` (401), `OTP_LOCKED`, `RATE_LIMITED`, `ACCOUNT_LOCKED`
(429), `ACCOUNT_BANNED`, `ACCOUNT_SUSPENDED` (403), `REFRESH_TOKEN_INVALID`,
`INVALID_CREDENTIALS`, `MFA_CHALLENGE_EXPIRED`, `TOTP_INVALID` (401), `CONFLICT` (409),
`ROLE_INVALID` (422), as the NestJS API answered.
