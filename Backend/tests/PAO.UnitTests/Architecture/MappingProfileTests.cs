using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Mediation;
using PAO.Lib.Mapping;

namespace PAO.UnitTests.Architecture;

[Trait("Category", "Gate")]
public sealed class MappingProfileTests
{
    [Fact]
    public void Every_profile_in_PAO_Lib_is_registered_once_by_the_mediator_scan()
    {
        var expected = typeof(IMappingProfile).Assembly.GetTypes()
            .Where(t => t is { IsClass: true, IsAbstract: false } && typeof(IMappingProfile).IsAssignableFrom(t))
            .OrderBy(t => t.FullName).ToList();
        Assert.NotEmpty(expected);
        var services = new ServiceCollection().AddMediator(typeof(MediatorSetup).Assembly);
        // A profile registered by hand as well must not configure its maps twice.
        services.AddMediator(typeof(MediatorSetup).Assembly);
        var registered = services.Where(d => d.ServiceType == typeof(IMappingProfile))
            .Select(d => d.ImplementationType!).OrderBy(t => t.FullName).ToList();
        Assert.Equal(expected, registered);
        Assert.NotNull(services.BuildServiceProvider().GetRequiredService<IMapper>());
    }
}
