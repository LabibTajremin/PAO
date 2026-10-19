using System.Text.Json;
using PAO.Migrator;

namespace PAO.IntegrationTests.Areas;

public sealed class SeedCommandTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>
{
    [Fact]
    public async Task Seed_adds_the_demo_admins_outside_production_with_a_password()
    {
        var env = Hosts.Environment(database.Url);
        env["SEED_ADMIN_PASSWORD"] = "demo password 123";
        var output = new StringWriter();
        Assert.Equal(0, await new[] { "seed" }.RunMigrator(env, Hosts.Paths.Migrations, output, () => SeedCommand.Run(Hosts.Paths, env, output)));
        Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, env, output));
        Assert.Contains("migrate seed: 4 admins", output.ToString(), StringComparison.Ordinal);
        var prod = Hosts.Environment(database.Url, "prod");
        prod["SEED_ADMIN_PASSWORD"] = "demo password 123";
        var quiet = new StringWriter();
        Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, prod, quiet));
        Assert.DoesNotContain("admins", quiet.ToString(), StringComparison.Ordinal);
    }

    [Fact]
    public async Task Perf_seed_prints_the_load_test_fixture_and_refuses_production()
    {
        var env = Hosts.Environment(database.Url);
        Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, env, new StringWriter()));
        var output = new StringWriter();
        Assert.Equal(0, await new[] { "perf-seed", "3" }.RunMigrator(env, Hosts.Paths.Migrations, output, null, n => PerfSeedCommand.Run(Hosts.Paths, env, n, output)));
        var fixture = JsonDocument.Parse(output.ToString()).RootElement;
        Assert.Equal(50, fixture.GetProperty("tokens").GetArrayLength());
        Assert.Equal(23.7937, fixture.GetProperty("lat").GetDouble());
        Assert.Equal(2, await new[] { "perf-seed", "0" }.RunMigrator(env, Hosts.Paths.Migrations, new StringWriter(), null, _ => Task.FromResult(0)));
        var refused = new StringWriter();
        Assert.Equal(1, await PerfSeedCommand.Run(Hosts.Paths, Hosts.Environment(database.Url, "prod"), 1, refused));
        Assert.Contains("refuses", refused.ToString(), StringComparison.Ordinal);
    }
}
