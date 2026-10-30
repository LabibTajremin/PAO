using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace PAO.Gates;

/// <summary>
/// The size limits of ADR-0034: C# files at most 250 lines (400 under `Test/`), and
/// methods, constructors, accessors and local functions at most 40 lines.
/// </summary>
public static class SizeChecker
{
    /// <summary>Lines allowed in a source file.</summary>
    public const int SourceFileLimit = 250;

    /// <summary>Lines allowed in a test file.</summary>
    public const int TestFileLimit = 400;

    /// <summary>Lines allowed in one method.</summary>
    public const int MethodLimit = 40;

    /// <summary>Returns every violation under `root`, as `path: problem`; empty when all files fit.</summary>
    public static IReadOnlyList<string> Check(string root)
    {
        var problems = new List<string>();
        foreach (var file in SourceFiles(root))
        {
            var relative = Path.GetRelativePath(root, file).Replace('\\', '/');
            problems.AddRange(CheckFile(relative, File.ReadAllText(file)));
        }
        return problems;
    }

    /// <summary>The violations of one file with path `relative` (relative to the backend folder).</summary>
    public static IEnumerable<string> CheckFile(string relative, string text)
    {
        var limit = relative.StartsWith("Test/", StringComparison.Ordinal) ? TestFileLimit : SourceFileLimit;
        var lines = text.TrimEnd('\n').Split('\n').Length;
        if (lines > limit)
        {
            yield return $"{relative}: {lines} lines (limit {limit})";
        }
        var tree = CSharpSyntaxTree.ParseText(text);
        foreach (var node in tree.GetRoot().DescendantNodes().Where(IsFunction))
        {
            var span = tree.GetLineSpan(node.Span);
            var length = span.EndLinePosition.Line - span.StartLinePosition.Line + 1;
            if (length > MethodLimit)
            {
                yield return $"{relative}:{span.StartLinePosition.Line + 1}: {Name(node)} has {length} lines (limit {MethodLimit})";
            }
        }
    }

    private static bool IsFunction(SyntaxNode node) =>
        node is BaseMethodDeclarationSyntax or AccessorDeclarationSyntax or LocalFunctionStatementSyntax;

    private static string Name(SyntaxNode node) => node switch
    {
        MethodDeclarationSyntax m => m.Identifier.Text,
        ConstructorDeclarationSyntax c => c.Identifier.Text,
        LocalFunctionStatementSyntax l => l.Identifier.Text,
        _ => node.Kind().ToString(),
    };

    /// <summary>Hand-written C# files under `root`: build output and generated files are skipped.</summary>
    public static IEnumerable<string> SourceFiles(string root) =>
        Directory.EnumerateFiles(root, "*.cs", SearchOption.AllDirectories)
            .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.Ordinal)
                && !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.Ordinal)
                && !f.EndsWith(".g.cs", StringComparison.Ordinal))
            .Order(StringComparer.Ordinal);
}
