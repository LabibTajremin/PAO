using System.Collections;
using System.Text;
using PAO.EF;
using PAO.EF.Connection;
using PAO.Infrastructure.Crypto;
using PAO.Migrator;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

/// <summary>`migrate create-admin` and `migrate reencrypt` (ADR-0036).</summary>
public sealed class LaunchCommandTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>
{
    // Production refuses the console SMS and log push adapters; FCM credentials are read only on first push.
    private Hashtable Prod()
    {
        var env = Hosts.Environment(database.Url, "prod");
        env["SMS_ADAPTER"] = "sslwireless";
        env["SSLWIRELESS_API_TOKEN"] = "token";
        env["SSLWIRELESS_SID"] = "sid";
        env["PUSH_ADAPTER"] = "fcm";
        env["FCM_CREDENTIALS_JSON"] = "{}";
        return env;
    }

    private async Task<int> Migrate(Hashtable env, TextWriter output, params string[] args) =>
        await args.RunMigrator(env, Hosts.Paths.Migrations, output, commands: new Dictionary<string, Func<string[], Task<int>>>
        {
            ["create-admin"] = rest => CreateAdminCommand.Run(Hosts.Paths, env, rest, output),
            ["reencrypt"] = _ => ReencryptCommand.Run(Hosts.Paths, env, output),
        });

    private async Task<object?> Scalar(string sql)
    {
        await using var dataSource = PaoDbContextSetup.CreateDataSource(PostgresUrl.ToConnectionString(database.Url));
        await using var command = dataSource.CreateCommand(sql);
        return await command.ExecuteScalarAsync();
    }

    [Fact]
    public async Task Create_admin_makes_one_super_admin_in_production_from_the_environment_password()
    {
        var env = Prod();
        var output = new StringWriter();
        Assert.Equal(1, await Migrate(env, output, "create-admin", "--email", "Owner@PAO.com.bd", "--name", "Owner"));
        Assert.Contains("ADMIN_PASSWORD is required", output.ToString(), StringComparison.Ordinal);
        Assert.Equal(2, await Migrate(env, output, "create-admin", "--email", "owner@pao.com.bd"));
        Assert.Equal(2, await Migrate(env, output, "create-admin", "--mail", "x", "--name", "y"));
        env["ADMIN_PASSWORD"] = "short";
        Assert.Equal(1, await Migrate(env, output, "create-admin", "--name", "Owner", "--email", "owner@pao.com.bd"));
        Assert.Contains("password", output.ToString(), StringComparison.OrdinalIgnoreCase);
        env["ADMIN_PASSWORD"] = "a long launch password";
        Assert.Equal(0, await Migrate(env, output, "create-admin", "--email", "Owner@PAO.com.bd", "--name", "Owner"));
        Assert.Contains("created super admin", output.ToString(), StringComparison.Ordinal);
        env["ADMIN_PASSWORD"] = "another long password";
        Assert.Equal(0, await Migrate(env, output, "create-admin", "--email", "owner@pao.com.bd", "--name", "Someone"));
        Assert.Contains("already exists; nothing changed", output.ToString(), StringComparison.Ordinal);
        Assert.Equal("super_admin|Owner|false", await Scalar("""
            SELECT r.role || '|' || a.name || '|' || c.must_change_password FROM identity.accounts a
            JOIN identity.account_roles r ON r.account_id = a.id JOIN identity.admin_credentials c ON c.account_id = a.id
            WHERE a.email = 'owner@pao.com.bd'
            """));
        Assert.True(await SecretHasher.Verify("a long launch password",
            (string)(await Scalar("SELECT c.password_hash FROM identity.admin_credentials c JOIN identity.accounts a ON a.id = c.account_id WHERE a.email = 'owner@pao.com.bd'"))!));
    }

    [Fact]
    public async Task Reencrypt_moves_every_field_to_the_current_key_once()
    {
        var original = Convert.FromBase64String(TestEnvironment.Key);
        var next = System.Security.Cryptography.RandomNumberGenerator.GetBytes(32);
        var old = new DataCipher(original);
        var provider = Guid.NewGuid();
        await Scalar($"""
            INSERT INTO verification.nid_records (provider_id, nid_ciphertext, nid_hash)
            VALUES ('{provider}', decode('{Convert.ToHexString(old.Encrypt("1234567890"u8.ToArray()))}', 'hex'), '{old.LookupHash("1234567890")}')
            """);
        var env = Hosts.Environment(database.Url);
        env["DATA_ENCRYPTION_KEY"] = Convert.ToBase64String(next);
        env["DATA_ENCRYPTION_PREVIOUS_KEYS"] = TestEnvironment.Key;
        var output = new StringWriter();
        Assert.Equal(0, await Migrate(env, output, "reencrypt"));
        Assert.Contains("verification.nid_records.nid_ciphertext: 1 rows", output.ToString(), StringComparison.Ordinal);
        var stored = (byte[])(await Scalar($"SELECT nid_ciphertext FROM verification.nid_records WHERE provider_id = '{provider}'"))!;
        Assert.Equal("1234567890", Encoding.UTF8.GetString(new DataCipher(next).Decrypt(stored)));
        var again = new StringWriter();
        Assert.Equal(0, await Migrate(env, again, "reencrypt"));
        Assert.Contains("verification.nid_records.nid_ciphertext: 0 rows", again.ToString(), StringComparison.Ordinal);
        Assert.Contains("identity.admin_credentials.totp_secret_enc: 0 rows", again.ToString(), StringComparison.Ordinal);
    }
}
