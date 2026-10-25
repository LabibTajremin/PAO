using System.Globalization;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Data.Migrations;

/// <summary>One goose-format migration file, split into the statements of each direction.</summary>
public sealed record GooseMigration(
    long Version,
    string Source,
    IReadOnlyList<string> Up,
    IReadOnlyList<string> Down,
    bool NoTransaction);

/// <summary>
/// Parses goose SQL migrations (`-- +goose Up/Down`, `StatementBegin/End`,
/// `NO TRANSACTION`) exactly as goose does, so both apply the same statements.
/// </summary>
public static partial class GooseParser
{
    /// <summary>The version goose reads from a file name (`0001_init.sql` is 1), or null.</summary>
    public static long? VersionOf(string fileName)
    {
        var match = FileName().Match(fileName);
        return match.Success ? long.Parse(match.Groups[1].Value, CultureInfo.InvariantCulture) : null;
    }

    /// <summary>Parses the file `source` (e.g. `identity/0001_init.sql`) with text `sql`.</summary>
    public static GooseMigration Parse(string source, string sql)
    {
        var version = VersionOf(source.Split('/')[^1])
            ?? throw new FormatException($"{source}: migration file names start with a version, e.g. 0001_init.sql");
        var state = new ParseState(source);
        foreach (var line in sql.Split('\n'))
        {
            var text = line.TrimEnd('\r');
            var annotation = Annotation().Match(text.Trim());
            if (annotation.Success)
            {
                state.Annotate(annotation.Groups[1].Value);
            }
            else
            {
                state.AddLine(text);
            }
        }
        state.Flush();
        if (!state.SawUp)
        {
            throw new FormatException($"{source}: missing \"-- +goose Up\" annotation");
        }
        return new GooseMigration(version, source, state.Up, state.Down, state.NoTransaction);
    }

    [GeneratedRegex(@"^(\d+)_.*\.sql$")]
    private static partial Regex FileName();

    [GeneratedRegex(@"^--\s*\+goose\s+(.+?)\s*$", RegexOptions.IgnoreCase)]
    private static partial Regex Annotation();

    [GeneratedRegex("--.*$")]
    private static partial Regex LineComment();

    private sealed class ParseState(string source)
    {
        private readonly List<string> buffer = [];
        private List<string>? direction;
        private bool inBlock;

        public List<string> Up { get; } = [];
        public List<string> Down { get; } = [];
        public bool NoTransaction { get; private set; }
        public bool SawUp { get; private set; }

        public void Annotate(string command)
        {
            switch (command.ToLowerInvariant())
            {
                case "up":
                    Flush();
                    direction = Up;
                    SawUp = true;
                    return;
                case "down":
                    Flush();
                    direction = Down;
                    return;
                case "statementbegin":
                    inBlock = true;
                    return;
                case "statementend":
                    inBlock = false;
                    Flush();
                    return;
                case "no transaction":
                    NoTransaction = true;
                    return;
                case "envsub on" or "envsub off":
                    throw new FormatException($"{source}: goose ENVSUB is not supported");
                default:
                    throw new FormatException($"{source}: unknown goose annotation \"{command}\"");
            }
        }

        public void AddLine(string line)
        {
            if (direction is null)
            {
                return;
            }
            buffer.Add(line);
            // Goose ends a statement at a line whose last non-comment text ends with a semicolon.
            if (!inBlock && LineComment().Replace(line, string.Empty).TrimEnd().EndsWith(';'))
            {
                Flush();
            }
        }

        public void Flush()
        {
            var statement = string.Join('\n', buffer).Trim();
            buffer.Clear();
            if (statement.Length > 0 && direction is not null)
            {
                direction.Add(statement);
            }
        }
    }
}
