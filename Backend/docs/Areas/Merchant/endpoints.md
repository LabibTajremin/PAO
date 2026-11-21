# Merchant area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
Paths keep `/v1/provider/...`. Errors map through `MerchantErrorMap`.

| Controller | Operations | Attribute |
|---|---|---|
| `EnrolmentController` | `GET /v1/provider/enrolment`, `PUT …/personal`, `…/services`, `…/area`, `…/emergency-contact`, `…/code-of-conduct`, `POST …/emergency-contact/verify` | `[Merchant(Permission = "provider:manage:own")]` |
| `MerchantControllers` | the file holding the three controllers below and the error map | |
| `MerchantProfileController` | `GET/PUT /v1/provider/profile` | `[Merchant(Permission = "provider:manage:own")]` |
| `PresenceController` | `POST /v1/provider/presence/online`, `…/heartbeat`, `…/offline` | `[Merchant(Permission = "provider:manage:own")]` |
| `PublicProfileController` | `GET /v1/customer/providers/{providerId}` | `[Customer(Permission = "provider:browse")]` |

The document steps (`nid`, `selfie`, `police-clearance`, `skill-proof`) and `/v1/provider/verification` belong to Verification.
