# Customer area — data

Schema `customer`, created by the scripts in `database/changes/customer/` ([database index](../../Database/README.md)).
EF models: `src/PAO.EF/Customer/CustomerRecords.cs` (`CustomerProfileRecord`, `AddressRecord` with a PostGIS `geography(Point)`).

| Table | Created by |
|---|---|
| `customer.customers` | `database/changes/customer/0001_init.sql`, admin copies in `0002_admin.sql` |
| `customer.addresses` | `database/changes/customer/0001_init.sql` |
| `customer.outbox` | `database/changes/customer/0001_init.sql` |
| `customer.processed_events` | `database/changes/customer/0001_init.sql` |
| `customer.places` | `database/changes/customer/0003_places.sql` |

| Repository | Role |
|---|---|
| `CustomerRepository` | profile upsert with its outbox event, admin search (keyset, literal LIKE), erase/status/booking copies for the subscribers |
| `AddressRepository` | address writes under `SELECT … FOR UPDATE` on the customer row, reads default first |
| `PlaceRepository` | whole-table replace through a binary COPY into a temp table, trigram search (`<%`, `word_similarity`) and the nearest place by `ST_DWithin` |
