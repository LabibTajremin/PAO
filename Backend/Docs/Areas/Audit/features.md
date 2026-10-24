# Audit area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Request | Use case |
|---|---|---|
| `ListAuditEntries` | `ListAuditEntriesQuery` | The audit viewer (A-08): filters by actor, action, subject and time range, newest first, cursor-paged on (at, id); a malformed cursor is a 422. |
