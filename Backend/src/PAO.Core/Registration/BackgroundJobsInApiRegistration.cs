using PAO.BackgroundJobs;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Hosting;

namespace PAO.Core.Registration;

/// <summary>
/// Lets the API process run the worker's relay and jobs when no worker service exists (the
/// MVP on one free instance, ADR-0036 §14). It reuses the worker's own registration, so
/// both hosts always run the same set.
/// </summary>
public static class BackgroundJobsInApiRegistration
{
    /// <summary>
    /// With `Jobs:RunInApi` (JOBS_IN_API=true) adds exactly what
    /// <see cref="WorkerServices.AddBackgroundJobs"/> adds for the worker: the bus with every
    /// area's subscribers, the outbox relay, the scheduler with every job and the hosted loop
    /// that the API's start and stop run. Off, it adds nothing.
    /// </summary>
    public static IServiceCollection AddBackgroundJobsInApi(this IServiceCollection services, PaoSettings settings, PaoPaths paths) =>
        settings.Jobs.RunInApi ? services.AddBackgroundJobs(paths) : services;
}
