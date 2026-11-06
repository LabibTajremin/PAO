using PAO.Infrastructure.Data.Migrations;
using PAO.Infrastructure.Hosting;

namespace PAO.Migrator;

/// <summary>
/// `migrate bundle [--check]`: writes "DB Changes/bundle/schema.sql" (<see cref="SchemaBundle"/>)
/// and "seed.sql" (<see cref="SeedBundle"/>); with `--check` it only compares and fails when
/// either is out of date, the CI gate. Needs no database.
/// </summary>
public static class BundleCommand
{
    /// <summary>The bundle folder inside "DB Changes".</summary>
    public const string FolderName = "bundle";

    /// <summary>The generated files by name, from the scripts and the seed file under `paths`.</summary>
    public static IReadOnlyDictionary<string, string> Generate(PaoPaths paths)
    {
        var files = new MigrationFiles(paths.Migrations);
        var (categories, _) = SeedFile.Parse(File.ReadAllText(SeedCommand.CatalogFile(paths)));
        return new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["schema.sql"] = SchemaBundle.Build(files.ReadModuleLists().Modules, files.Load),
            ["seed.sql"] = SeedBundle.Build(categories),
        };
    }

    /// <summary>Runs the command with `args` (empty or `--check`); returns the exit code.</summary>
    public static async Task<int> Run(PaoPaths paths, string[] args, TextWriter output)
    {
        if (args is not ([] or ["--check"]))
        {
            await output.WriteLineAsync("usage: migrate bundle [--check]");
            return 2;
        }
        var folder = Path.Combine(paths.Migrations, FolderName);
        var stale = new List<string>();
        foreach (var (name, text) in Generate(paths))
        {
            var path = Path.Combine(folder, name);
            var current = File.Exists(path) ? await File.ReadAllTextAsync(path) : null;
            if (current == text)
            {
                continue;
            }
            stale.Add(name);
            if (args.Length == 0)
            {
                Directory.CreateDirectory(folder);
                await File.WriteAllTextAsync(path, text);
            }
        }
        if (args.Length == 1 && stale.Count > 0)
        {
            await output.WriteLineAsync(
                $"migrate bundle: {string.Join(", ", stale)} out of date in \"DB Changes/{FolderName}\"; run Backend/scripts/gen-db-bundle.sh");
            return 1;
        }
        await output.WriteLineAsync(args.Length == 1 ? "migrate bundle: up to date" : $"migrate bundle: wrote {stale.Count} file(s)");
        return 0;
    }
}
