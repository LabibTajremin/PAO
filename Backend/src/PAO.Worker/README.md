# PAO.Worker

The background process: relays the outbox to event handlers and runs the scheduled jobs.

It runs from the same image as the API (`/app/worker`). The jobs themselves are in `PAO.BackgroundJobs`; this project only hosts them.

## Run it

```sh
cd Backend && dotnet run --project src/PAO.Worker
```

## Open these first

- `Program.cs`
- `WorkerHost.cs`: what the worker starts
- `../PAO.BackgroundJobs/WorkerServices.cs`: the jobs and the relay it registers
