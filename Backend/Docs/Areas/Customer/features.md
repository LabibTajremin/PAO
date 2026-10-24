# Customer area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Profile` | `GetCustomerProfile` | query | profile with the account phone and, with a photo, a signed URL; PROFILE_NOT_FOUND before set-up |
| `Profile` | `SaveCustomerProfile` | command | name 2–80 code points, `en`/`bn`; a photo must be the customer's own confirmed avatar; publishes `CustomerProfileSaved` |
| `Addresses` | `ListAddresses` | query | default first, then newest |
| `Addresses` | `AddAddress`, `UpdateAddress`, `SetDefaultAddress`, `DeleteAddress` | command | validators check label, lines and the Bangladesh box (OUTSIDE_SERVICE_AREA); writes hold the customer's row lock; up to 10; the first is the default; deleting the default promotes the newest |
| `ServiceArea` | `CheckServiceArea` | query | the launch-area polygon from Admin's `service_area.geojson`; empty covers everywhere, unreadable covers nothing |

Favourites: the NestJS customer module and the spec have no favourites, so there is nothing to port.
