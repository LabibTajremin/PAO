using System.Text.Json;
using System.Text.RegularExpressions;

namespace PAO.Gates;

/// <summary>
/// Documentation coverage (ADR-0034): every area, feature, controller, service, repository,
/// job, config file and section, and DB script has its page or index entry under `Docs/`,
/// and no Markdown link points at a missing file.
/// </summary>
public static partial class DocsChecker
{
    /// <summary>The pages every area folder holds.</summary>
    public static readonly IReadOnlyList<string> AreaPages = ["overview.md", "features.md", "endpoints.md", "data.md", "events.md"];

    /// <summary>Returns every gap under the backend folder `root`; empty when the docs are complete.</summary>
    public static IReadOnlyList<string> Check(string root)
    {
        var problems = new List<string>();
        var docs = Path.Combine(root, "Docs");
        foreach (var area in Directories(Path.Combine(root, "PAO.Core", "Areas")))
        {
            CheckArea(root, docs, Path.GetFileName(area), problems);
        }
        Mentioned(problems, Path.Combine(docs, "Api", "README.md"), Files(Path.Combine(root, "PAO.Core", "Platform"), "*Controller.cs").Select(Stem), "controller");
        Mentioned(problems, Path.Combine(docs, "Operations", "jobs.md"), Jobs(root), "job");
        CheckConfig(root, docs, problems);
        Mentioned(problems, Path.Combine(docs, "Database", "README.md"), Scripts(root), "script");
        CheckLinks(root, problems);
        return problems;
    }

    private static void CheckArea(string root, string docs, string area, List<string> problems)
    {
        var source = Path.Combine(root, "PAO.Core", "Areas", area);
        var pages = Path.Combine(docs, "Areas", area);
        foreach (var page in AreaPages.Where(p => !File.Exists(Path.Combine(pages, p))))
        {
            problems.Add($"Docs/Areas/{area}/{page}: missing page for area {area}");
        }
        Mentioned(problems, Path.Combine(pages, "features.md"), Directories(Path.Combine(source, "Features")).Select(Path.GetFileName)!, "feature");
        Mentioned(problems, Path.Combine(pages, "endpoints.md"), Files(Path.Combine(source, "Controllers"), "*.cs").Select(Stem), "controller");
        Mentioned(problems, Path.Combine(pages, "overview.md"), Files(Path.Combine(source, "Services"), "*.cs", SearchOption.AllDirectories).Select(Stem), "service");
        Mentioned(problems, Path.Combine(pages, "data.md"), Files(Path.Combine(source, "Repositories"), "*.cs").Select(Stem), "repository");
    }

    private static void CheckConfig(string root, string docs, List<string> problems)
    {
        var expected = new List<string>();
        foreach (var file in Files(Path.Combine(root, "Config"), "*.json"))
        {
            expected.Add(Path.GetFileName(file));
            using var json = JsonDocument.Parse(File.ReadAllText(file));
            expected.AddRange(json.RootElement.EnumerateObject().Select(p => p.Name));
        }
        Mentioned(problems, Path.Combine(docs, "Config", "README.md"), expected, "config file or section");
    }

    private static IEnumerable<string> Jobs(string root) =>
        Directory.EnumerateFiles(root, "*.cs", SearchOption.AllDirectories)
            .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}Test{Path.DirectorySeparatorChar}", StringComparison.Ordinal))
            .SelectMany(f => JobClass().Matches(File.ReadAllText(f)).Select(m => m.Groups[1].Value));

    private static IEnumerable<string> Scripts(string root)
    {
        var dir = Path.Combine(root, "DB Changes");
        return Files(dir, "*.sql", SearchOption.AllDirectories).Select(f => Path.GetRelativePath(dir, f).Replace('\\', '/'));
    }

    private static void CheckLinks(string root, List<string> problems)
    {
        foreach (var page in Files(root, "*.md", SearchOption.AllDirectories).Where(f => !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.Ordinal)))
        {
            foreach (Match link in Link().Matches(File.ReadAllText(page)))
            {
                var target = link.Groups[1].Value.Split('#')[0];
                if (target.Length == 0 || target.Contains("://", StringComparison.Ordinal) || target.StartsWith("mailto:", StringComparison.Ordinal))
                {
                    continue;
                }
                var resolved = Path.GetFullPath(Path.Combine(Path.GetDirectoryName(page)!, Uri.UnescapeDataString(target)));
                if (!File.Exists(resolved) && !Directory.Exists(resolved))
                {
                    problems.Add($"{Path.GetRelativePath(root, page).Replace('\\', '/')}: broken link {target}");
                }
            }
        }
    }

    private static void Mentioned(List<string> problems, string page, IEnumerable<string> names, string what)
    {
        var list = names.ToList();
        var text = File.Exists(page) ? File.ReadAllText(page) : null;
        foreach (var name in list.Where(n => text is null || !text.Contains(n, StringComparison.Ordinal)))
        {
            problems.Add($"{Path.GetFileName(Path.GetDirectoryName(page))}/{Path.GetFileName(page)}: no entry for {what} {name}");
        }
    }

    private static IEnumerable<string> Directories(string path) =>
        Directory.Exists(path) ? Directory.GetDirectories(path).Order(StringComparer.Ordinal) : [];

    private static IEnumerable<string> Files(string path, string pattern, SearchOption option = SearchOption.TopDirectoryOnly) =>
        Directory.Exists(path) ? Directory.GetFiles(path, pattern, option).Order(StringComparer.Ordinal) : [];

    private static string Stem(string file) => Path.GetFileNameWithoutExtension(file);

    [GeneratedRegex(@"class\s+(\w+)[^{;]*\bIScheduledJob\b")]
    private static partial Regex JobClass();

    [GeneratedRegex(@"\]\(([^)\s]+)\)")]
    private static partial Regex Link();
}
