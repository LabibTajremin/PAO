# PAO.Lib

Shared contracts with no infrastructure: request and view models, events, error reasons, mapping and validation.

Every other project may depend on it; it depends on nothing of ours. Keep it free of database, HTTP and Redis code.

## Open these first

- `Areas/`: the contract types per area
- `Errors/`: the error reasons the API returns
- `Events/`: the events areas publish to each other
