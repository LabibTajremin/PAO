// The migration tool (`migrate up|seed|perf-seed N`). Composition root: one named call (excluded from coverage; the
// start-up smoke tests run it).
using PAO.Infrastructure.Hosting;
using PAO.Migrator;

try
{
    var paths = PaoPaths.Current();
    var environment = Environment.GetEnvironmentVariables();
    return await args.RunMigrator(
        environment, paths.Migrations, Console.Out,
        () => SeedCommand.Run(paths, environment, Console.Out),
        n => PerfSeedCommand.Run(paths, environment, n, Console.Out));
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"migrate failed\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.ToString())}}}");
    return 1;
}
