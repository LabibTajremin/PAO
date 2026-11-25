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
| `Places` | `SearchPlaces` | query | OpenStreetMap places (ADR-0042): text normalised (lower case, Bangla digits as ASCII), 2–80 characters; trigram word similarity ≥ 0.4, then area, street, place, address, then nearest to `lat`/`lng`; up to 10; Bangla titles for `lang=bn` when OSM has one; cached in Redis for a day by query and rounded point |
| `Places` | `ReversePlace` | query | the nearest non-area place within 300 m of a pin; OUTSIDE_SERVICE_AREA ("coming soon") outside the launch area, NOT_FOUND with nothing near; cached for a day |
| `Places` | `ImportPlaces` | request | `migrate import-places FILE` and the dev seed: replaces the whole table from GeoJSON-sequence lines in one transaction, skipping unnamed lines, then names each place's area from the nearest area within 3 km; the seed keeps a non-empty table |

Favourites: the spec has no favourites, so there is nothing to implement.
