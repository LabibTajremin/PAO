// The migration tool (`migrate up|seed|perf-seed N|create-admin|reencrypt`). Composition root:
// one named call (excluded from coverage; the start-up smoke tests run it).
using PAO.Infrastructure.Hosting;
using PAO.Migrator;

try
{
    var paths = PaoPaths.Current();
    var environment = Environment.GetEnvironmentVariables();
    return await args.RunMigrator(
        environment, paths.Migrations, Console.Out,
        () => SeedCommand.Run(paths, environment, Console.Out),
        n => PerfSeedCommand.Run(paths, environment, n, Console.Out),
        new Dictionary<string, Func<string[], Task<int>>>(StringComparer.Ordinal)
        {
            ["create-admin"] = rest => CreateAdminCommand.Run(paths, environment, rest, Console.Out),
            ["reencrypt"] = _ => ReencryptCommand.Run(paths, environment, Console.Out),
        });
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"migrate failed\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.ToString())}}}");
    return 1;
}
