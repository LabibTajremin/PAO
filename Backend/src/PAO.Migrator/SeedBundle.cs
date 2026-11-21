using System.Globalization;
using System.Text;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using static PAO.Lib.Areas.Catalog.CatalogMappingProfile;

namespace PAO.Migrator;

/// <summary>
/// Writes the reference data `migrate seed` loads (`Seed/catalog.yaml`) as one idempotent
/// script (`bundle/seed.sql`): the same upserts, ids and price rule as the SeedCatalog
/// command, in one transaction. The demo admins are left out: they need a password hash
/// and exist only outside production.
/// </summary>
public static class SeedBundle
{
    /// <summary>The script that seeds `categories`.</summary>
    public static string Build(IReadOnlyList<SeedCategory> categories)
    {
        var sql = new StringBuilder(Header);
        sql.Append("BEGIN;\n");
        var prices = new List<string>();
        foreach (var (c, order) in categories.Select((c, i) => (c, i)))
        {
            var id = SeedIds.For("category", c.Key);
            sql.Append($"\n-- {c.Key}\n");
            sql.Append(Upsert(
                "catalog.categories",
                ["id", "name_en", "name_bn", "icon_key", "sort_order", "published"],
                [Uuid(id), Str(c.Name.En), Str(c.Name.Bn), Str(c.Icon), Int(order), "true"]));
            foreach (var (s, sortOrder) in c.Services.Select((s, i) => (s, i)))
            {
                AppendService(sql, prices, id, s, sortOrder);
            }
        }
        sql.Append(Prices(prices));
        sql.Append(Announce);
        sql.Append("\nCOMMIT;\n");
        return sql.ToString();
    }

    private static void AppendService(StringBuilder sql, List<string> prices, Guid categoryId, SeedService s, int sortOrder)
    {
        var id = SeedIds.For("service", s.Key);
        sql.Append(Upsert(
            "catalog.services",
            ["id", "category_id", "name_en", "name_bn", "icon_key", "service_model", "required_level", "search_radius_m",
                "women_providers_only", "requires_level_2", "level2_checklist", "sort_order", "published"],
            [Uuid(id), Uuid(categoryId), Str(s.Name.En), Str(s.Name.Bn), Str(s.Icon), Str(s.Model), Int(s.RequiredLevel),
                Int(s.SearchRadiusM), Bool(s.WomenProvidersOnly), Bool(s.RequiresLevel2), Json(s.Level2Checklist), Int(sortOrder), "true"]));
        foreach (var (sub, order) in s.SubServices.Select((x, i) => (x, i)))
        {
            var subId = SeedIds.For("sub-service", sub.Key);
            sql.Append(Upsert(
                "catalog.sub_services",
                ["id", "service_id", "name_en", "name_bn", "description", "inclusions", "exclusions", "unit", "max_quantity", "sort_order", "published"],
                [Uuid(subId), Uuid(id), Str(sub.Name.En), Str(sub.Name.Bn), Json(new Text { En = string.Empty, Bn = string.Empty }),
                    Json(Array.Empty<Text>()), Json(Array.Empty<Text>()), Str(sub.Unit), Int(sub.MaxQuantity), Int(order), "true"]));
            prices.Add($"    ({Uuid(subId)}::uuid, {sub.PricePaisa.ToString(CultureInfo.InvariantCulture)})");
        }
    }

    // Columns the seed owns are overwritten; created_at and the current price stay.
    private static string Upsert(string table, string[] columns, string[] values)
    {
        var updates = string.Join(", ", columns.Skip(1).Select(c => $"{c} = excluded.{c}"));
        return $"INSERT INTO {table} ({string.Join(", ", columns)}, created_at, updated_at)\n"
            + $"VALUES ({string.Join(", ", values)}, now(), now())\n"
            + $"ON CONFLICT (id) DO UPDATE SET {updates}, updated_at = excluded.updated_at;\n";
    }

    // A new immutable price version only where the current one differs, as SeedCatalog does.
    private static string Prices(List<string> rows) => $"""

        -- Prices: a new version only for a sub-service without one or with another amount.
        WITH wanted (sub_service_id, amount_paisa) AS (VALUES
        {string.Join(",\n", rows)}
        ), added AS (
            INSERT INTO catalog.price_versions (id, sub_service_id, amount_paisa, effective_from, created_by)
            SELECT gen_random_uuid(), w.sub_service_id, w.amount_paisa, now(), '00000000-0000-0000-0000-000000000000'
            FROM wanted w
            JOIN catalog.sub_services s ON s.id = w.sub_service_id
            LEFT JOIN catalog.price_versions p ON p.id = s.current_price_version_id
            WHERE p.amount_paisa IS DISTINCT FROM w.amount_paisa
            RETURNING id, sub_service_id
        )
        UPDATE catalog.sub_services s SET current_price_version_id = a.id FROM added a WHERE s.id = a.sub_service_id;

        """;

    private const string Announce = """

        -- Bump the catalog version (expiring cached trees) and announce it, as every catalog write does.
        WITH v AS (UPDATE catalog.catalog_version SET version = version + 1 RETURNING version)
        INSERT INTO catalog.outbox (id, aggregate_id, event_name, payload, created_at, next_attempt_at)
        SELECT gen_random_uuid(), 'catalog', 'catalog.CatalogChanged',
               jsonb_build_object('name', 'catalog.CatalogChanged', 'version', v.version), now(), now()
        FROM v;
        """;

    private static string Uuid(Guid id) => $"'{id}'";

    private static string Str(string value) => "'" + value.Replace("'", "''", StringComparison.Ordinal) + "'";

    private static string Int(int value) => value.ToString(CultureInfo.InvariantCulture);

    private static string Bool(bool value) => value ? "true" : "false";

    private static string Json<T>(T value) => Str(ToJson(value)) + "::jsonb";

    private const string Header = """
        -- Generated by `migrate bundle` (Backend/scripts/gen-db-bundle.sh) from Seed/catalog.yaml;
        -- do not edit. CI fails when it is out of date.
        --
        -- The reference data `/app/migrate seed` loads: the catalog (categories, services,
        -- sub-services, prices), with the same stable ids. Run it after schema.sql. Idempotent:
        -- rows are upserted (ON CONFLICT DO UPDATE) and a price version is added only when the
        -- price changed; like `migrate seed`, a rerun only touches updated_at, bumps the
        -- catalog version and announces it in the catalog outbox. The demo
        -- admins of `migrate seed` (dev/staging only) are not included; create the first admin
        -- with `/app/migrate create-admin`.

        """;
}
