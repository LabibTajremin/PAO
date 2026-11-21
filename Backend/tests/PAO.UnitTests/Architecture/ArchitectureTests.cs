using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using NetArchTest.Rules;
using PAO.Core;
using PAO.Core.Registration;
using PAO.Lib.Mediator;

namespace PAO.UnitTests.Architecture;

[Trait("Category", "Gate")]
public sealed class ArchitectureTests
{
    private static readonly Assembly Core = typeof(ApiHost).Assembly;

    private static void Holds(NetArchTest.Rules.TestResult result) =>
        Assert.True(result.IsSuccessful, string.Join(", ", result.FailingTypeNames ?? []));

    [Theory]
    [InlineData("PAO.EF", new[] { "PAO.Lib", "PAO.Infrastructure", "PAO.Core", "PAO.BackgroundJobs", "PAO.Worker", "PAO.Migrator" })]
    [InlineData("PAO.Lib", new[] { "PAO.Infrastructure", "PAO.Core", "PAO.BackgroundJobs", "PAO.Worker", "PAO.Migrator" })]
    [InlineData("PAO.Infrastructure", new[] { "PAO.Core", "PAO.BackgroundJobs", "PAO.Worker", "PAO.Migrator" })]
    [InlineData("PAO.BackgroundJobs", new[] { "PAO.Core", "PAO.Worker", "PAO.Migrator" })]
    [InlineData("PAO.Core", new[] { "PAO.Worker", "PAO.Migrator" })]
    public void Projects_depend_only_downwards(string project, string[] forbidden)
    {
        var assembly = Assembly.Load(project);
        Holds(Types.InAssembly(assembly).ShouldNot().HaveDependencyOnAny(forbidden).GetResult());
    }

    // JOBS_IN_API (ADR-0036 §14) lets the MVP run the relay and jobs inside the API, so the
    // API references PAO.BackgroundJobs, but only its one registration class may use it.
    [Fact]
    public void Only_the_jobs_in_api_registration_uses_the_background_jobs()
    {
        Holds(Types.InAssembly(Core).That().DoNotHaveName(nameof(BackgroundJobsInApiRegistration))
            .ShouldNot().HaveDependencyOn("PAO.BackgroundJobs").GetResult());
        Assert.True(Types.InAssembly(Core).That().HaveName(nameof(BackgroundJobsInApiRegistration))
            .Should().HaveDependencyOn("PAO.BackgroundJobs").GetResult().IsSuccessful);
    }

    [Fact]
    public void Areas_reach_other_areas_only_through_their_shared_services()
    {
        foreach (var area in AreasRegistration.Names)
        {
            var others = AreasRegistration.Names.Where(a => a != area).ToArray();
            var forbidden = others.SelectMany(o => new[]
            {
                $"PAO.Core.Areas.{o}.Controllers", $"PAO.Core.Areas.{o}.Features", $"PAO.Core.Areas.{o}.Repositories",
            }).ToArray();
            Holds(Types.InAssembly(Core).That().ResideInNamespace($"PAO.Core.Areas.{area}")
                .ShouldNot().HaveDependencyOnAny(forbidden).GetResult());
        }
    }

    [Fact]
    public void Every_area_has_its_folders_shared_service_and_registration()
    {
        foreach (var area in AreasRegistration.Names)
        {
            Assert.NotNull(Core.GetType($"PAO.Core.Areas.{area}.Services.Shared.I{area}SharedService"));
            Assert.NotNull(Core.GetType($"PAO.Core.Registration.{area}AreaRegistration"));
        }
        var services = new Microsoft.Extensions.DependencyInjection.ServiceCollection();
        Assert.Same(services, services.AddAreas().AddRepositories());
    }

    public static IEnumerable<Type> Controllers(Assembly assembly) =>
        assembly.GetTypes().Where(t => typeof(ControllerBase).IsAssignableFrom(t) && !t.IsAbstract);

    [Fact]
    public void Controllers_depend_only_on_the_mediator_and_areas_name_their_area()
    {
        foreach (var controller in Controllers(Core))
        {
            var parameters = controller.GetConstructors().SelectMany(c => c.GetParameters());
            Assert.All(parameters, p => Assert.Equal(typeof(IMediator), p.ParameterType));
            var ns = controller.Namespace!;
            if (ns.StartsWith("PAO.Core.Areas.", StringComparison.Ordinal))
            {
                Assert.Equal(ns.Split('.')[3], controller.GetCustomAttribute<AreaAttribute>()?.RouteValue);
            }
        }
    }
}
