# Admin area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
Errors map through `AdminErrorMap`.

| Controller | Operations | Attribute |
|---|---|---|
| `ComplaintsControllers` | the file holding the error map and the two controllers below | |
| `ComplaintsController` | `GET /v1/admin/complaints`, `GET …/{complaintId}`, `POST …/assign`, `…/comments` (201), `…/resolve` | `[Admin(Permission = "complaint:manage")]` |
| `ReportsController` | `POST /v1/customer/bookings/{bookingId}/reports`, `POST /v1/provider/jobs/{bookingId}/reports` (201) | `[AllUserType(Permission = "complaint:create")]` |
| `ConsoleControllers` | the file holding the four controllers below | |
| `SettingsController` | `GET /v1/admin/settings`, `PUT …/{key}` | `[Admin(Permission = "settings:read" / "settings:manage")]` |
| `DashboardController` | `GET /v1/admin/dashboard` | `[Admin(Permission = "dashboard:read")]` |
| `AdminProvidersController` | `GET /v1/admin/providers`, `GET …/{providerId}`, `POST …/status` | `[Admin(Permission = "provider:read" / "provider:manage")]` |
| `AdminCustomersController` | `GET /v1/admin/customers`, `GET …/{customerId}`, `POST …/status` | `[Admin(Permission = "customer:read" / "customer:manage")]` |
