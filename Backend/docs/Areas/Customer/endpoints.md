# Customer area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
All live in `Controllers/CustomerControllers.cs` with `CustomerErrorMap`.

| Controller | Operations | Attribute |
|---|---|---|
| `CustomerProfileController` | `GET/PUT /v1/customer/profile` | `[Customer(Permission = "profile:manage:own")]` |
| `AddressesController` | `GET/POST /v1/customer/addresses`, `PUT/DELETE /v1/customer/addresses/{addressId}`, `POST /v1/customer/addresses/{addressId}/default` | `[Customer(Permission = "address:manage:own")]` |
| `ServiceAreaController` | `GET /v1/customer/service-area` | `[AllUserType(Permission = "catalog:read")]` |
| `CustomerControllers` | the file holding the three controllers and the error map | |

Errors: PROFILE_NOT_FOUND 404, NOT_FOUND 404, VALIDATION_FAILED 422, UPLOAD_INVALID 422,
OUTSIDE_SERVICE_AREA 422, ADDRESS_LIMIT_REACHED 409, PROFILE_REQUIRED 409.
