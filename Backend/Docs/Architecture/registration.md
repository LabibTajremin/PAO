# Service registration

`Program.cs` of each host only calls named extension methods, one concern each, every one in
its own file under the project's `Registration/` folder (ADR-0034):

| Method | File | Registers |
|---|---|---|
| `AddPaoSettings` | `PAO.Infrastructure/Registration/SettingsRegistration.cs` | config files + environment, validation, Serilog, listen URL |
| `AddBuiltInServices` | `PAO.Infrastructure/Registration/BuiltInServicesRegistration.cs` | options, HTTP clients, health checks, controllers with the edge filters |
| `AddCustomServices` | `PAO.Infrastructure/Registration/CustomServicesRegistration.cs` | mediator, mapper, clock, ids, crypto, Redis helpers, RBAC, storage, SMS, push, outbox, metrics |
| `AddDatabase` | `PAO.Infrastructure/Registration/DatabaseRegistration.cs` | Npgsql data source, `PaoDbContext` factory and scoped context |
| `AddRepositories` | `PAO.Core/Registration/RepositoriesRegistration.cs` | repositories |
| `Add<Area>Area` | `PAO.Core/Registration/<Area>AreaRegistration.cs` | the area's handlers, validators, services and shared contract |
| `AddAreas` | `PAO.Core/Registration/AreasRegistration.cs` | calls every `Add<Area>Area` |
| `AddBackgroundJobs` | `PAO.BackgroundJobs/WorkerServices.cs` | bus, relay, scheduler, platform jobs (the worker, and the API with `JOBS_IN_API=true`) |
| `AddBackgroundJobsInApi` | `PAO.Core/Registration/BackgroundJobsInApiRegistration.cs` | the API's call: `AddBackgroundJobs` when `Jobs:RunInApi`, nothing otherwise ([events and jobs](events-and-jobs.md#running-the-jobs-in-the-api)) |

`ApiHost.RunApi`, `WorkerHost.RunWorker` and `MigratorCommand.RunMigrator` run the built
hosts; `PlatformStartup.Prepare` checks Postgres, Redis and the buckets first and logs
where the background jobs run (`background jobs: in api` or `in worker`).
