using PAO.Infrastructure.Data.Migrations;

namespace PAO.Infrastructure.Hosting;

/// <summary>
/// Where a host finds `Config/`, `Logs/` and `DB Changes/`: PAO_HOME when set, else the
/// backend folder of a checkout (the one holding PAO.sln) above the binaries, else the
/// binaries' folder (`/app` in the image).
/// </summary>
public sealed record PaoPaths(string Home, string BaseDirectory)
{
    /// <summary>The non-secret configuration files.</summary>
    public string Config => Path.Combine(Home, "Config");

    /// <summary>The goose-format SQL scripts.</summary>
    public string Migrations => Path.Combine(Home, MigrationFiles.FolderName);

    /// <summary>The bundled OpenAPI document, copied next to the API binaries.</summary>
    public string Spec => Path.Combine(BaseDirectory, "Spec", Http.OpenApi.SpecDocument.FileName);

    /// <summary>Resolves the paths for binaries in `baseDirectory`.</summary>
    public static PaoPaths Resolve(string baseDirectory, string? home)
    {
        if (!string.IsNullOrEmpty(home))
        {
            return new PaoPaths(home, baseDirectory);
        }
        for (var dir = new DirectoryInfo(baseDirectory); dir is not null; dir = dir.Parent)
        {
            if (File.Exists(Path.Combine(dir.FullName, "PAO.sln")))
            {
                return new PaoPaths(dir.FullName, baseDirectory);
            }
        }
        return new PaoPaths(baseDirectory, baseDirectory);
    }

    /// <summary>The paths of the running process.</summary>
    public static PaoPaths Current() => Resolve(AppContext.BaseDirectory, Environment.GetEnvironmentVariable("PAO_HOME"));
}
