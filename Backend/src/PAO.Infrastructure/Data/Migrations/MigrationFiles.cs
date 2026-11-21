using System.Text.Json;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Data.Migrations;

/// <summary>The module folders in apply order, and the modules that own an outbox table.</summary>
public sealed record ModuleLists(IReadOnlyList<string> Modules, IReadOnlyList<string> OutboxModules);

/// <summary>
/// Reads "DB Changes": `modules.json` and each module's `NNNN_name.sql` scripts, the only
/// schema source (ADR-0034).
/// </summary>
public sealed partial class MigrationFiles(string directory)
{
    /// <summary>The folder name next to the hosts and in the image.</summary>
    public const string FolderName = "DB Changes";

    /// <summary>The directory the scripts are read from.</summary>
    public string Directory { get; } = directory;

    /// <summary>Reads `modules.json`.</summary>
    public ModuleLists ReadModuleLists()
    {
        using var document = JsonDocument.Parse(File.ReadAllText(Path.Combine(Directory, "modules.json")));
        return new ModuleLists(Names(document.RootElement, "modules"), Names(document.RootElement, "outboxModules"));
    }

    /// <summary>Loads one module's migrations, sorted by version.</summary>
    public IReadOnlyList<GooseMigration> Load(string module)
    {
        if (!ModuleName().IsMatch(module))
        {
            throw new ArgumentException($"invalid migration module name \"{module}\"", nameof(module));
        }
        var folder = Path.Combine(Directory, module);
        var files = System.IO.Directory.Exists(folder)
            ? System.IO.Directory.GetFiles(folder, "*.sql").Where(f => GooseParser.VersionOf(Path.GetFileName(f)) is not null).ToArray()
            : [];
        if (files.Length == 0)
        {
            throw new InvalidOperationException($"no migrations found for module {module}");
        }
        return [.. files
            .Select(f => GooseParser.Parse($"{module}/{Path.GetFileName(f)}", File.ReadAllText(f)))
            .OrderBy(m => m.Version)];
    }

    private static string[] Names(JsonElement root, string field)
    {
        if (!root.TryGetProperty(field, out var list) || list.ValueKind != JsonValueKind.Array
            || list.EnumerateArray().Any(v => v.ValueKind != JsonValueKind.String || !ModuleName().IsMatch(v.GetString()!)))
        {
            throw new InvalidOperationException($"modules.json: {field} must be a list of module names");
        }
        return [.. list.EnumerateArray().Select(v => v.GetString()!)];
    }

    [GeneratedRegex("^[a-z][a-z0-9_]*$")]
    private static partial Regex ModuleName();
}
