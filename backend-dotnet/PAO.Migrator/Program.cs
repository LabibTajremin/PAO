// The migration tool (`migrate up`). Composition root: one named call (excluded from coverage; the
// start-up smoke tests run it).
using PAO.Infrastructure.Hosting;
using PAO.Migrator;

try
{
    return await args.RunMigrator(Environment.GetEnvironmentVariables(), PaoPaths.Current().Migrations, Console.Out);
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"migrate failed\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.ToString())}}}");
    return 1;
}
