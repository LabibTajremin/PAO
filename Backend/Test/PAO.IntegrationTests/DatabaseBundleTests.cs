using Npgsql;
using PAO.Migrator;
using PAO.TestKit;

namespace PAO.IntegrationTests;

/// <summary>"DB Changes/bundle": schema.sql equals `migrate up`, seed.sql equals `migrate seed`.</summary>
public sealed class DatabaseBundleTests : IAsyncLifetime
{
    // Everything `migrate up` leaves behind that a script could get wrong.
    private const string Shape = """
        SELECT string_agg(x, E'\n' ORDER BY x) FROM (
          SELECT 'col ' || table_schema || '.' || table_name || '.' || column_name || ' ' || data_type || ' ' || is_nullable || ' ' || coalesce(column_default, '') AS x
          FROM information_schema.columns WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'tiger', 'topology')
          UNION ALL SELECT 'idx ' || indexdef FROM pg_indexes WHERE schemaname NOT IN ('pg_catalog', 'tiger', 'topology')
          UNION ALL SELECT 'con ' || conrelid::regclass || ' ' || conname || ' ' || pg_get_constraintdef(oid) FROM pg_constraint WHERE connamespace::regnamespace::text NOT IN ('pg_catalog', 'tiger', 'topology')
          UNION ALL SELECT 'trg ' || tgrelid::regclass || ' ' || tgname FROM pg_trigger WHERE NOT tgisinternal
          UNION ALL SELECT 'ext ' || extname FROM pg_extension
        ) q
        """;

    // Seeded content, without the generated price ids and timestamps.
    private const string Catalog = """
        SELECT string_agg(x, E'\n' ORDER BY x) FROM (
          SELECT concat_ws('|', c.id, c.name_en, c.name_bn, c.icon_key, c.sort_order, c.published) AS x FROM catalog.categories c
          UNION ALL SELECT concat_ws('|', s.id, s.category_id, s.name_en, s.name_bn, s.icon_key, s.service_model, s.required_level,
            s.search_radius_m, s.women_providers_only, s.requires_level_2, s.level2_checklist, s.sort_order, s.published) FROM catalog.services s
          UNION ALL SELECT concat_ws('|', u.id, u.service_id, u.name_en, u.name_bn, u.description, u.inclusions, u.exclusions, u.unit,
            u.max_quantity, u.sort_order, u.published, p.amount_paisa, p.created_by) FROM catalog.sub_services u
            LEFT JOIN catalog.price_versions p ON p.id = u.current_price_version_id
          UNION ALL SELECT 'prices ' || count(*) FROM catalog.price_versions
          UNION ALL SELECT 'version ' || version FROM catalog.catalog_version
          UNION ALL SELECT 'event ' || aggregate_id || ' ' || event_name || ' ' || payload FROM catalog.outbox
        ) q
        """;

    private string migrated = string.Empty;
    private string bundled = string.Empty;

    public async ValueTask InitializeAsync()
    {
        migrated = await TestDatabases.CreateMigrated();
        bundled = await TestDatabases.CreateEmpty();
    }

    public async ValueTask DisposeAsync()
    {
        await TestDatabases.Drop(migrated);
        await TestDatabases.Drop(bundled);
    }

    private static async Task<string> Query(string url, string sql)
    {
        await using var connection = await TestDatabases.Open(url);
        await using var command = new NpgsqlCommand(sql, connection);
        return (string)(await command.ExecuteScalarAsync())!;
    }

    private static async Task Run(string url, string name)
    {
        await using var connection = await TestDatabases.Open(url);
        await TestDatabases.Execute(connection, BundleCommand.Generate(Hosts.Paths)[name]);
    }

    private static string Versions(IEnumerable<string> modules) =>
        string.Join(" UNION ALL ", modules.Select(m => $"SELECT '{m} ' || version_id || ' ' || is_applied AS x FROM goose_{m}"));

    [Fact]
    public async Task Schema_sql_equals_migrate_up_and_seed_sql_equals_migrate_seed()
    {
        await Run(bundled, "schema.sql");
        await Run(bundled, "schema.sql");
        Assert.Equal(await Query(migrated, Shape), await Query(bundled, Shape));
        var modules = new PAO.Infrastructure.Data.Migrations.MigrationFiles(TestDatabases.MigrationsDirectory).ReadModuleLists().Modules;
        var versions = $"SELECT string_agg(x, ',' ORDER BY x) FROM ({Versions(modules)}) q";
        Assert.Equal(await Query(migrated, versions), await Query(bundled, versions));
        await TestDatabases.Migrate(bundled);
        Assert.Equal(await Query(migrated, versions), await Query(bundled, versions));

        Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, Hosts.Environment(migrated), new StringWriter()));
        await Run(bundled, "seed.sql");
        Assert.Equal(await Query(migrated, Catalog), await Query(bundled, Catalog));
        Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, Hosts.Environment(migrated), new StringWriter()));
        await Run(bundled, "seed.sql");
        Assert.Equal(await Query(migrated, Catalog), await Query(bundled, Catalog));
    }
}
