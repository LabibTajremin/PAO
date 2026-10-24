# Authorisation

Every controller action carries exactly one attribute (deny by default; a test fails
otherwise):

| Attribute | Spec `x-permission` | Runtime check |
|---|---|---|
| `[AllowAnonymous]` | `public` (`security: []`) | none |
| `[AllUserType]` | `authenticated` | valid token |
| `[AllUserType(Permission = p)]` | `p` held by both customer and provider roles | RBAC grants `p` |
| `[Customer(Permission = p)]` | `p` held only by customers | RBAC grants `p` |
| `[Merchant(Permission = p)]` | `p` held only by providers | RBAC grants `p` |
| `[Admin(Permission = p)]` | `p` held only by admin roles | RBAC grants `p` |
| `[Admin]` | — | any admin role |
| `[PermissionFromSpec]` | the matched operation's | only on the 501 catch-all |

The attribute names the audience; the permission is what RBAC enforces, so `super_admin`
keeps every grant it has in `identity.role_permissions`, as with NestJS. A second test
checks each action's attribute against its operation's `x-permission` and security.

## Tokens and RBAC

- Access tokens are EdDSA (Ed25519) JWTs signed with BouncyCastle: header
  `{"alg":"EdDSA","kid","typ":"JWT"}`, claims `roles, ver, sid, iss=pao, sub, exp, iat, jti`
  in the NestJS order. A test signs byte for byte the token NestJS (jose) signed with the
  same seed and verifies it. `JWT_SIGNING_KEY` is the 32-byte seed; previous public keys in
  `JWT_PREVIOUS_PUBLIC_KEYS` still verify during rotation.
- Revoked token ids: `pao:{env}:deny:jti:{jti}`.
- Grants: `RbacChecker` reads `pao:{env}:rbac:role:{role}:v{n}` and
  `rbac:screens:{role}:v{n}` (marker `~`, 1 h TTL), loading all missing roles in one query
  from `identity.role_permissions` / `role_screens` through EF.
