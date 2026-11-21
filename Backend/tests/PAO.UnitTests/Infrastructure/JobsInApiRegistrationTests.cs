using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PAO.BackgroundJobs;
using PAO.Core.Registration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Jobs;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class JobsInApiRegistrationTests
{
    private static readonly PaoPaths Paths = PaoPaths.Resolve(AppContext.BaseDirectory, null);

    private static List<string> Described(IServiceCollection services) =>
        services.Select(d => $"{d.Lifetime} {d.ServiceType.FullName} {d.ImplementationType?.FullName}").ToList();

    [Fact]
    public void Off_the_api_registers_no_background_service()
    {
        var services = new ServiceCollection();
        Assert.Same(services, services.AddBackgroundJobsInApi(TestSettings.Create(), Paths));
        Assert.Empty(services);
    }

    [Fact]
    public void On_the_api_registers_exactly_what_the_worker_registers()
    {
        var settings = TestSettings.Create();
        settings.Jobs.RunInApi = true;
        var api = new ServiceCollection().AddBackgroundJobsInApi(settings, Paths);
        var worker = new ServiceCollection().AddBackgroundJobs(Paths);
        Assert.Equal(Described(worker), Described(api));
        Assert.Equal(typeof(WorkerLoop), Assert.Single(api, d => d.ServiceType == typeof(IHostedService)).ImplementationType);
        Assert.Equal(7, api.Count(d => d.ServiceType == typeof(IScheduledJob)));
    }
}
