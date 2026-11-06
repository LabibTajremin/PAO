using PAO.Infrastructure.Data.Migrations;
using PAO.Infrastructure.Hosting;
using PAO.Migrator;

namespace PAO.UnitTests.Infrastructure;

public sealed class DatabaseBundleTests : IDisposable
{
    private static readonly PaoPaths Repository = PaoPaths.Resolve(AppContext.BaseDirectory, null);
    private readonly string home = Directory.CreateTempSubdirectory("pao-bundle").FullName;

    public DatabaseBundleTests()
    {
        foreach (var file in Directory.GetFiles(Repository.Migrations, "*", SearchOption.AllDirectories))
        {
            var target = Path.Combine(home, MigrationFiles.FolderName, Path.GetRelativePath(Repository.Migrations, file));
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            File.Copy(file, target);
        }
        Directory.CreateDirectory(Path.Combine(home, "Seed"));
        File.Copy(SeedCommand.CatalogFile(Repository), SeedCommand.CatalogFile(Paths));
    }

    private PaoPaths Paths => new(home, AppContext.BaseDirectory);

    private string Bundled(string name) => Path.Combine(Paths.Migrations, BundleCommand.FolderName, name);

    public void Dispose() => Directory.Delete(home, recursive: true);

    [Fact]
    public void The_committed_bundle_is_up_to_date()
    {
        foreach (var (name, text) in BundleCommand.Generate(Repository))
        {
            Assert.Equal(text, File.ReadAllText(Path.Combine(Repository.Migrations, BundleCommand.FolderName, name)));
        }
    }

    [Fact]
    public async Task Writes_checks_and_reports_stale_files()
    {
        var output = new StringWriter();
        Assert.Equal(2, await BundleCommand.Run(Paths, ["--force"], output));
        Assert.Equal(0, await BundleCommand.Run(Paths, ["--check"], output));
        File.AppendAllText(Bundled("seed.sql"), "-- edited\n");
        File.Delete(Bundled("schema.sql"));
        Assert.Equal(1, await BundleCommand.Run(Paths, ["--check"], output));
        Assert.False(File.Exists(Bundled("schema.sql")));
        Assert.Equal(0, await BundleCommand.Run(Paths, [], output));
        Assert.Equal(0, await BundleCommand.Run(Paths, ["--check"], output));
        Assert.Equal(0, await BundleCommand.Run(Paths, [], output));
        var log = output.ToString();
        Assert.Contains("usage: migrate bundle [--check]", log, StringComparison.Ordinal);
        Assert.Contains("migrate bundle: schema.sql, seed.sql out of date", log, StringComparison.Ordinal);
        Assert.Contains("migrate bundle: wrote 2 file(s)", log, StringComparison.Ordinal);
        Assert.Contains("migrate bundle: wrote 0 file(s)", log, StringComparison.Ordinal);
    }

    [Fact]
    public void Records_each_version_once_and_guards_it()
    {
        var sql = SchemaBundle.Build(["identity"], _ => [new GooseMigration(7, "identity/0007_x.sql", ["SELECT 1;", "SELECT 2;"], [], false)]);
        Assert.Contains("CREATE TABLE IF NOT EXISTS goose_identity", sql, StringComparison.Ordinal);
        Assert.Contains("IF NOT EXISTS (SELECT 1 FROM goose_identity WHERE version_id = 7) THEN", sql, StringComparison.Ordinal);
        Assert.Contains("EXECUTE $pao_stmt$SELECT 2;$pao_stmt$;", sql, StringComparison.Ordinal);
        Assert.Contains("INSERT INTO goose_identity (version_id, is_applied) VALUES (7, true);", sql, StringComparison.Ordinal);
    }

    [Theory]
    [InlineData("SELECT 1;", true, "uses NO TRANSACTION")]
    [InlineData("SELECT '$pao_stmt$';", false, "reserved dollar-quote tag")]
    [InlineData("SELECT '$pao_bundle$';", false, "reserved dollar-quote tag")]
    public void Refuses_what_a_do_block_cannot_replay(string statement, bool noTransaction, string message)
    {
        var error = Assert.Throws<InvalidOperationException>(() =>
            SchemaBundle.Build(["audit"], _ => [new GooseMigration(1, "audit/0001_x.sql", [statement], [], noTransaction)]));
        Assert.Contains(message, error.Message, StringComparison.Ordinal);
    }
}
