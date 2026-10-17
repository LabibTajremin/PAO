using System.Collections;
using PAO.EF;
using PAO.EF.Connection;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data.Migrations;

namespace PAO.Migrator;

/// <summary>
/// The migration tool: `migrate up` applies every pending script in "DB Changes" and
/// records versions in the `goose_&lt;module&gt;` tables, exactly as the NestJS migrator did.
/// `seed` and `perf-seed N` return with the areas that own the seed data (P17 tasks 2–4).
/// </summary>
public static class MigratorCommand
{
    /// <summary>The usage line printed for anything else.</summary>
    public const string Usage = "usage: migrate up";

    /// <summary>Runs `args` and returns the process exit code; messages go to `output`.</summary>
    public static async Task<int> Run(string[] args, IDictionary environment, string migrationsDirectory, TextWriter output)
    {
        if (args is not ["up"])
        {
            await output.WriteLineAsync(Usage);
            return 2;
        }
        var url = LegacyEnvironment.Map(environment).GetValueOrDefault("Database:Url")
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
