# Customer area — data

Schema `customer`, created by the scripts in `DB Changes/customer/` ([database index](../../Database/README.md)).
EF models: `PAO.EF/Customer/CustomerRecords.cs` (`CustomerProfileRecord`, `AddressRecord` with a PostGIS `geography(Point)`).

| Table | Created by |
|---|---|
| `customer.customers` | `DB Changes/customer/0001_init.sql`, admin copies in `0002_admin.sql` |
| `customer.addresses` | `DB Changes/customer/0001_init.sql` |
| `customer.outbox` | `DB Changes/customer/0001_init.sql` |
| `customer.processed_events` | `DB Changes/customer/0001_init.sql` |

| Repository | Role |
|---|---|
| `CustomerRepository` | profile upsert with its outbox event, admin search (keyset, literal LIKE), erase/status/booking copies for the subscribers |
| `AddressRepository` | address writes under `SELECT … FOR UPDATE` on the customer row, reads default first |
