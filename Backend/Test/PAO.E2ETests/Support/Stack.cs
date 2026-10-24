namespace PAO.E2ETests.Support;

/// <summary>Where the e2e stack listens and the seeded admins' password.</summary>
public sealed record Stack(string Api, string Worker, string AdminPassword)
{
    private static Stack? loaded;

    /// <summary>
    /// The directory infra/e2e/stack.sh writes .stack.env and .admins.env into: PAO_E2E_STATE,
    /// or out/e2e under the repository root.
    /// </summary>
    public static string StateDir
    {
        get
        {
            var set = Environment.GetEnvironmentVariable("PAO_E2E_STATE");
            return string.IsNullOrEmpty(set) ? Path.Combine(RepoRoot(), "out", "e2e") : set;
        }
    }

    /// <summary>The running stack, from the environment or else the state file.</summary>
    public static Stack Current => loaded ??= Load();

    /// <summary>Parses KEY=value lines; a missing file reads as empty.</summary>
    public static Dictionary<string, string> ReadEnv(string path)
    {
        var env = new Dictionary<string, string>();
        if (!File.Exists(path))
        {
            return env;
        }
        foreach (var row in File.ReadAllLines(path))
        {
            var at = row.IndexOf('=', StringComparison.Ordinal);
            if (at > 0)
            {
                env[row[..at]] = row[(at + 1)..];
            }
        }
        return env;
    }

    private static Stack Load()
    {
        var file = ReadEnv(Path.Combine(StateDir, ".stack.env"));
        string Value(string key)
        {
            var found = Environment.GetEnvironmentVariable(key);
            if (string.IsNullOrEmpty(found) && !file.TryGetValue(key, out found))
            {
                throw new InvalidOperationException($"{key} is not set: start the stack with infra/e2e/stack.sh");
            }
            return found;
        }
        return new Stack(Value("PAO_E2E_API"), Value("PAO_E2E_WORKER"), Value("PAO_E2E_ADMIN_PASSWORD"));
    }

    private static string RepoRoot()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            if (File.Exists(Path.Combine(dir.FullName, "pao")) && Directory.Exists(Path.Combine(dir.FullName, "Backend")))
            {
                return dir.FullName;
            }
        }
        throw new InvalidOperationException("repository root not found; set PAO_E2E_STATE");
    }
}
