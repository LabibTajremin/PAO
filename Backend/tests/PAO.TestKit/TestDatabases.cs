using System.Security.Cryptography;
using Npgsql;
using PAO.Infrastructure.Data.Migrations;
using PAO.Infrastructure.Hosting;

namespace PAO.TestKit;

/// <summary>
/// Private Postgres databases per test class, cloned from a migrated template built once per
/// migration set (ADR-0008). Other agents share the server, so only databases created here
/// are ever dropped.
/// </summary>
public static class TestDatabases
{
    private const long TemplateLock = 424_244;

    /// <summary>"DB Changes" of this checkout.</summary>
    public static string MigrationsDirectory => PaoPaths.Resolve(AppContext.BaseDirectory, null).Migrations;

    /// <summary>Creates a fresh, empty database and returns its URL.</summary>
    public static Task<string> CreateEmpty() => Create(template: null);

    /// <summary>Creates a database with every script of "DB Changes" applied.</summary>
    public static async Task<string> CreateMigrated() => await Create(await EnsureTemplate());

    /// <summary>Drops a database this kit created.</summary>
    public static async Task Drop(string url)
    {
        var name = new Uri(url).AbsolutePath.Trim('/');
        await Admin($"DROP DATABASE IF EXISTS {name} WITH (FORCE)");
    }

    private static async Task<string> Create(string? template)
    {
        var name = TestEnvironment.Unique("pao_net_test_");
        await Admin($"CREATE DATABASE {name}{(template is null ? string.Empty : $" TEMPLATE {template}")}");
        return TestEnvironment.WithDatabase(TestEnvironment.DatabaseUrl, name);
    }

    private static async Task<string> EnsureTemplate()
    {
        var name = "pao_net_tpl_" + MigrationsHash();
        await using var admin = await Open(TestEnvironment.DatabaseUrl);
        await Execute(admin, $"SELECT pg_advisory_lock({TemplateLock})");
        try
        {
            await using var exists = new NpgsqlCommand($"SELECT 1 FROM pg_database WHERE datname = '{name}'", admin);
            if (await exists.ExecuteScalarAsync() is null)
            {
                await Execute(admin, $"CREATE DATABASE {name}");
                await Migrate(TestEnvironment.WithDatabase(TestEnvironment.DatabaseUrl, name));
            }
        }
        finally
        {
            await Execute(admin, $"SELECT pg_advisory_unlock({TemplateLock})");
        }
        return name;
    }

    /// <summary>Applies every script of "DB Changes" to the database at `url`.</summary>
    public static async Task Migrate(string url)
    {
        await using var dataSource = PAO.EF.PaoDbContextSetup.CreateDataSource(PAO.EF.Connection.PostgresUrl.ToConnectionString(url));
        var files = new MigrationFiles(MigrationsDirectory);
        await new GooseMigrator(dataSource, files.Load, files.ReadModuleLists().Modules).Up(CancellationToken.None);
    }

    private static string MigrationsHash()
    {
        var dir = MigrationsDirectory;
        using var sha = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        foreach (var file in Directory.GetFiles(dir, "*", SearchOption.AllDirectories).Order(StringComparer.Ordinal))
        {
            sha.AppendData(System.Text.Encoding.UTF8.GetBytes(Path.GetRelativePath(dir, file) + "\n"));
            sha.AppendData(File.ReadAllBytes(file));
        }
        return Convert.ToHexStringLower(sha.GetHashAndReset())[..16];
    }

    private static async Task Admin(string sql)
    {
        await using var connection = await Open(TestEnvironment.DatabaseUrl);
        await Execute(connection, sql);
    }

    /// <summary>Opens a connection to `url`.</summary>
    public static async Task<NpgsqlConnection> Open(string url)
    {
        var connection = new NpgsqlConnection(PAO.EF.Connection.PostgresUrl.ToConnectionString(url));
        await connection.OpenAsync();
        return connection;
    }

    /// <summary>Runs one statement.</summary>
    public static async Task Execute(NpgsqlConnection connection, string sql)
    {
        await using var command = new NpgsqlCommand(sql, connection);
        await command.ExecuteNonQueryAsync();
    }
}
