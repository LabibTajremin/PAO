# Audit area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).

| Controller | Operation | Route | Attribute |
|---|---|---|---|
| `AuditController` | listAuditEntries | `GET /v1/admin/audit` | `[Admin(Permission = "audit:read")]` |

Empty actor role, reason and before/after states are left out of each entry.
