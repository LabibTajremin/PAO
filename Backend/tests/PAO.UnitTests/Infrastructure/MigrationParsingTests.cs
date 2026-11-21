using System.Text.Json.Nodes;
using PAO.Infrastructure.Data.Migrations;
using PAO.Infrastructure.Http.OpenApi;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class GooseParserTests
{
    private const string Sql = """
        -- leading comment, ignored
        -- +goose Up
        -- +goose NO TRANSACTION
        CREATE TABLE a (id int); -- trailing comment
        INSERT INTO a
        VALUES (1);
        -- +goose StatementBegin
        CREATE FUNCTION f() RETURNS int AS $$
        BEGIN RETURN 1; END;
        $$ LANGUAGE plpgsql;
        -- +goose StatementEnd
        SELECT 1
        -- +goose Down
        DROP TABLE a;
        """;

    [Fact]
    public void Splits_statements_like_goose()
    {
        var m = GooseParser.Parse("identity/0002_more.sql", Sql.Replace("\n", "\r\n", StringComparison.Ordinal));
        Assert.Equal(2, m.Version);
        Assert.True(m.NoTransaction);
        Assert.Equal(4, m.Up.Count);
        Assert.Equal("INSERT INTO a\nVALUES (1);", m.Up[1]);
        Assert.StartsWith("CREATE FUNCTION", m.Up[2], StringComparison.Ordinal);
        Assert.Equal("SELECT 1", m.Up[3]);
        Assert.Equal(["DROP TABLE a;"], m.Down);
    }

    [Theory]
    [InlineData("x/init.sql", "-- +goose Up\nSELECT 1;", "start with a version")]
    [InlineData("x/0001_a.sql", "SELECT 1;", "missing \"-- +goose Up\"")]
    [InlineData("x/0001_a.sql", "-- +goose Up\n-- +goose ENVSUB ON", "ENVSUB is not supported")]
    [InlineData("x/0001_a.sql", "-- +goose Up\n-- +goose Sideways", "unknown goose annotation \"Sideways\"")]
    public void Rejects_what_goose_would_reject(string source, string sql, string message)
    {
        Assert.Contains(message, Assert.Throws<FormatException>(() => GooseParser.Parse(source, sql)).Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Reads_versions_from_file_names()
    {
        Assert.Equal(12, GooseParser.VersionOf("0012_x.sql"));
        Assert.Null(GooseParser.VersionOf("README.md"));
    }

    [Fact]
    public void A_schema_without_a_type_still_checks_its_other_keywords()
    {
        var validator = new SchemaValidator(new SpecDocument(new JsonObject()));
        Assert.Equal("x must be equal to one of the allowed values", validator.Validate(JsonValue.Create("b"), JsonNode.Parse("""{"enum":["a"]}"""), "x"));
    }
}

public sealed class MigrationFilesTests : IDisposable
{
    private readonly string dir = Directory.CreateTempSubdirectory("pao-mig").FullName;

    public void Dispose() => Directory.Delete(dir, recursive: true);

    [Fact]
    public void Reads_module_lists_and_sorted_migrations()
    {
        File.WriteAllText(Path.Combine(dir, "modules.json"), """{"modules":["a","b"],"outboxModules":["a"]}""");
        Directory.CreateDirectory(Path.Combine(dir, "a"));
        File.WriteAllText(Path.Combine(dir, "a", "0002_b.sql"), "-- +goose Up\nSELECT 2;");
        File.WriteAllText(Path.Combine(dir, "a", "0001_a.sql"), "-- +goose Up\nSELECT 1;");
        File.WriteAllText(Path.Combine(dir, "a", "notes.sql"), "ignored");
        var files = new MigrationFiles(dir);
        Assert.Equal(["a", "b"], files.ReadModuleLists().Modules);
        Assert.Equal([1L, 2L], files.Load("a").Select(m => m.Version));
        Assert.Throws<InvalidOperationException>(() => files.Load("b"));
        Assert.Throws<ArgumentException>(() => files.Load("../etc"));
    }

    [Theory]
    [InlineData("""{"modules":"a","outboxModules":[]}""")]
    [InlineData("""{"modules":["A"],"outboxModules":[]}""")]
    [InlineData("""{"modules":[1],"outboxModules":[]}""")]
    [InlineData("""{"modules":[]}""")]
    public void Rejects_malformed_module_lists(string json)
    {
        File.WriteAllText(Path.Combine(dir, "modules.json"), json);
        Assert.Throws<InvalidOperationException>(() => new MigrationFiles(dir).ReadModuleLists());
    }

    [Fact]
    public void The_repository_scripts_all_parse()
    {
        var files = new MigrationFiles(TestDatabases.MigrationsDirectory);
        var lists = files.ReadModuleLists();
        Assert.Equal(12, lists.Modules.Count);
        Assert.All(lists.Modules, m => Assert.NotEmpty(files.Load(m)));
    }
}
