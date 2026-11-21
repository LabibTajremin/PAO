# PAO.Core

The API host: every HTTP endpoint the three apps call.

Each business area (Identity, Booking, Billing, …) lives in `Areas/<Area>/` with its controllers, features (one folder per use case, CQRS style), services and repositories. `Platform/` holds the cross-cutting endpoints (health, the spec), `Registration/` wires everything into the host.

## Run it

```sh
cd Backend && dotnet run --project src/PAO.Core
```

## Open these first

- `Program.cs` and `ApiHost.cs`: how the host is built
- `Areas/Booking/`: the busiest area, a good model for the others
- `Registration/`: where a new area or service gets plugged in
