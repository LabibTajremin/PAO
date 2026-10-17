# Notification area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).

No controllers yet: until the area is ported, its operations in `api/openapi.yaml` are
answered by the catch-all `UnimplementedController` with 501 NOT_IMPLEMENTED after the full
edge checks ([API index](../../Api/README.md)).
