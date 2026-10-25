using System.Collections;
using PAO.EF;
using PAO.EF.Connection;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data.Migrations;

namespace PAO.Migrator;

/// <summary>
/// The migration tool: `migrate up` applies every pending script in "DB Changes" and
/// records versions in the `goose_&lt;module&gt;` tables, exactly as goose does.
/// `seed` loads the seed data through <see cref="SeedCommand"/>; `perf-seed N` puts N online
/// merchants in place for the load test through <see cref="PerfSeedCommand"/>.
/// </summary>
public static class MigratorCommand
{
    /// <summary>The usage line printed for anything else.</summary>
    public const string Usage = "usage: migrate up|seed|perf-seed N";

    /// <summary>
    /// Runs `args` and returns the process exit code; messages go to `output`. `seed` runs
    /// `migrate seed` and `perfSeed` runs `migrate perf-seed N` with N of at least one.
    /// </summary>
    public static async Task<int> RunMigrator(
        this string[] args, IDictionary environment, string migrationsDirectory, TextWriter output,
        Func<Task<int>>? seed = null, Func<int, Task<int>>? perfSeed = null)
    {
        if (args is ["seed"] && seed is not null)
        {
            return await seed();
        }
        if (args is ["perf-seed", var count] && perfSeed is not null && int.TryParse(count, out var n) && n >= 1)
        {
            return await perfSeed(n);
        }
        if (args is not ["up"])
        {
            await output.WriteLineAsync(Usage);
            return 2;
        }
        var url = EnvironmentVariables.Map(environment).GetValueOrDefault("Database:Url")
            ?? environment["Database__Url"] as string;
        if (string.IsNullOrEmpty(url))
        {
            await output.WriteLineAsync("migrate failed: DATABASE_URL is required");
            return 1;
        }
        await using var dataSource = PaoDbContextSetup.CreateDataSource(PostgresUrl.ToConnectionString(url));
        var files = new MigrationFiles(migrationsDirectory);
        await new GooseMigrator(dataSource, files.Load, files.ReadModuleLists().Modules).Up(CancellationToken.None);
        await output.WriteLineAsync("migrate up: done");
        return 0;
    }
}
