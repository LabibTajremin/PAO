# Customer area — overview

Customer profiles, saved addresses and launch areas.

Code: `PAO.Core/Areas/Customer/`; contracts: `PAO.Lib/Areas/Customer/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `ICustomerSharedService` | The only way other areas reach Customer (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetCustomer` | Returns a customer profile, or throws `customer.not_found`. |
| `GetAddress` | Returns one of the customer's saved addresses with its exact location, or throws `customer.address_not_found`. Callers reveal it to a merchant only after acceptance (PRD §11). |
| `IsInServiceArea` | Reports whether a point lies inside an active launch area (C35). |
| `SearchCustomers` | Lists customers with a profile for the admin console, newest first (A-05). |
