# Architecture

## Projects and dependency rules

| Project | Holds | May reference |
|---|---|---|
| `PAO.EF` | `PaoDbContext`, db models, `IEntityTypeConfiguration` classes, the design-time factory, `PostgresUrl` | nothing in PAO |
| `PAO.Lib` | request models, view models, DTOs, events, error reasons, `IMapper` and profiles, FluentValidation config, mediator abstractions | `PAO.EF` |
| `PAO.Infrastructure` | config, logging, data, migrator engine, Redis, RBAC, crypto, HTTP edge, mediator, events, outbox, storage, SMS, push, metrics, health, test hooks, `Registration/` | `PAO.Lib`, `PAO.EF` |
| `PAO.BackgroundJobs` | `JobScheduler`, `WorkerLoop`, platform jobs | `PAO.Infrastructure` |
| `PAO.Core` | the web API: `Areas/<Area>/`, `Registration/`, the 501 catch-all | `PAO.Infrastructure` |
| `PAO.Worker` | worker host | `PAO.Core`, `PAO.BackgroundJobs` |
| `PAO.Migrator` | migration tool | `PAO.Infrastructure` |
| `Tools/PAO.Gates` | size and docs checkers | nothing in PAO |

The architecture tests (`Test/PAO.UnitTests/Architecture`) enforce these rules, that areas
reach other areas only through `Services/Shared`, and that controllers depend only on
`IMediator`.

## Pages

- [Request flow (CQRS)](cqrs.md)
- [HTTP edge](http-edge.md)
- [Authorisation](authorization.md)
- [Events and jobs](events-and-jobs.md)
- [Service registration](registration.md)
