using Microsoft.EntityFrameworkCore;
using Npgsql;
using PAO.EF;
using PAO.EF.Connection;
using PAO.EF.Conventions;

namespace PAO.UnitTests.EF;

public sealed class SnakeCaseNamesTests
{
    [Theory]
    [InlineData("ScreenId", "screen_id")]
    [InlineData("HTTPStatus", "http_status")]
    [InlineData("Cancellations30d", "cancellations30d")]
    [InlineData("Level2Checklist", "level2_checklist")]
    [InlineData("id", "id")]
    [InlineData("IsAdmin", "is_admin")]
    public void Converts_property_names_to_column_names(string name, string column)
    {
        Assert.Equal(column, SnakeCaseNames.ToSnakeCase(name));
    }

    [Fact]
    public void The_model_maps_rbac_tables_in_the_identity_schema_with_snake_case_columns()
    {
        using var db = new DesignTimeDbContextFactory().CreateDbContext([]);
        var roleScreens = db.Model.FindEntityType(typeof(PAO.EF.Identity.RoleScreen))!;
        Assert.Equal("role_screens", roleScreens.GetTableName());
        Assert.Equal(Schemas.Identity, roleScreens.GetSchema());
        Assert.Equal(["role", "screen_id"], roleScreens.GetProperties().Select(p => p.GetColumnName()).Order());
        Assert.Equal("is_admin", db.Model.FindEntityType(typeof(PAO.EF.Identity.Role))!.FindProperty("IsAdmin")!.GetColumnName());
        Assert.NotNull(db.Roles);
        Assert.NotNull(db.Permissions);
        Assert.NotNull(db.RolePermissions);
        Assert.NotNull(db.Screens);
        Assert.NotNull(db.RoleScreens);
        Assert.Equal(QueryTrackingBehavior.NoTracking, db.ChangeTracker.QueryTrackingBehavior);
    }

    [Fact]
    public void The_design_time_factory_reads_database_url()
    {
        Environment.SetEnvironmentVariable("DATABASE_URL", "postgres://u:p@db.example:6543/other");
        try
        {
            using var db = new DesignTimeDbContextFactory().CreateDbContext([]);
            Assert.Contains("db.example", db.Database.GetConnectionString(), StringComparison.Ordinal);
        }
        finally
        {
            Environment.SetEnvironmentVariable("DATABASE_URL", null);
        }
    }
}

public sealed class PostgresUrlTests
{
    [Fact]
    public void Converts_a_url_with_credentials_and_ssl()
    {
        var cs = new NpgsqlConnectionStringBuilder(PostgresUrl.ToConnectionString(
            "postgres://pa%40o:se%3Acret@db:6543/pao%20db?sslmode=require&pool_max_conns=7&pool_max_conn_lifetime=1h30m&pool_max_conn_idle_time=90s&connect_timeout=5&application_name"));
        Assert.Equal("db", cs.Host);
        Assert.Equal(6543, cs.Port);
        Assert.Equal("pa@o", cs.Username);
        Assert.Equal("se:cret", cs.Password);
        Assert.Equal("pao db", cs.Database);
        Assert.Equal(SslMode.Require, cs.SslMode);
        Assert.Equal(7, cs.MaxPoolSize);
        Assert.Equal(5400, cs.ConnectionLifetime);
        Assert.Equal(90, cs.ConnectionIdleLifetime);
        Assert.Equal(5, cs.Timeout);
    }

    [Fact]
    public void Defaults_follow_pgxpool()
    {
        var cs = new NpgsqlConnectionStringBuilder(PostgresUrl.ToConnectionString("postgresql://localhost/pao"));
        Assert.Equal(5432, cs.Port);
        Assert.Null(cs.Username);
        Assert.Equal(Math.Max(4, Environment.ProcessorCount), cs.MaxPoolSize);
        Assert.Equal(3600, cs.ConnectionLifetime);
        Assert.Equal(1800, cs.ConnectionIdleLifetime);
        var userOnly = new NpgsqlConnectionStringBuilder(PostgresUrl.ToConnectionString("postgres://pao@localhost/pao?pool_max_conns=x"));
        Assert.Equal("pao", userOnly.Username);
        Assert.Null(userOnly.Password);
    }

    [Theory]
    [InlineData("disable", SslMode.Disable)]
    [InlineData("allow", SslMode.Allow)]
    [InlineData("prefer", SslMode.Prefer)]
    [InlineData("verify-ca", SslMode.VerifyCA)]
    [InlineData("verify-full", SslMode.VerifyFull)]
    public void Maps_every_sslmode(string mode, SslMode expected)
    {
        Assert.Equal(expected, new NpgsqlConnectionStringBuilder(PostgresUrl.ToConnectionString($"postgres://h/d?sslmode={mode}")).SslMode);
    }

    [Theory]
    [InlineData("mysql://h/d")]
    [InlineData("not a url")]
    [InlineData("postgres://h/d?sslmode=bogus")]
    public void Rejects_anything_else(string url)
    {
        Assert.Throws<FormatException>(() => PostgresUrl.ToConnectionString(url));
    }

    [Theory]
    [InlineData("90s", 90_000d)]
    [InlineData("1h30m", 5_400_000d)]
    [InlineData("250ms", 250d)]
    [InlineData("1.5m", 90_000d)]
    [InlineData("10", null)]
    [InlineData("1d", null)]
    public void Parses_go_durations(string text, double? ms)
    {
        Assert.Equal(ms, PostgresUrl.ParseGoDuration(text));
    }
}
