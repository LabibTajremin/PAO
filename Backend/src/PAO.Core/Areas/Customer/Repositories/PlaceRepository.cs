using Npgsql;
using NpgsqlTypes;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Customer.Repositories;

/// <summary>
/// `customer.places` (ADR-0042): the whole table replaced in one transaction by the import,
/// trigram search and the nearest place to a point.
/// </summary>
public sealed class PlaceRepository(NpgsqlDataSource data)
{
    /// <summary>How close a place must be to answer a reverse lookup, in metres.</summary>
    public const double ReverseRadiusM = 300;

    /// <summary>How far an area may be to name a place's area, in metres.</summary>
    public const double AreaRadiusM = 3000;

    // `<%` matches a query that is close to any run of words in the text; 0.4 keeps
    // "dhanmondi 27" matching "road 27 dhanmondi" without flooding short queries.
    private const string Threshold = "SET LOCAL pg_trgm.word_similarity_threshold = 0.4";

    /// <summary>Replaces every place with <paramref name="rows"/>; a repeated id keeps its first row. Returns the count.</summary>
    public async Task<int> Replace(IEnumerable<PlaceRow> rows, CancellationToken cancellationToken)
    {
        await using var conn = await data.OpenConnectionAsync(cancellationToken);
        await using var tx = await conn.BeginTransactionAsync(cancellationToken);
        await Run(conn, "CREATE TEMP TABLE places_load (id text, kind text, name_en text, name_bn text, area text, search_text text, lng float8, lat float8) ON COMMIT DROP", cancellationToken);
        await using (var copy = await conn.BeginBinaryImportAsync("COPY places_load FROM STDIN (FORMAT BINARY)", cancellationToken))
        {
            foreach (var r in rows)
            {
                await copy.StartRowAsync(cancellationToken);
                foreach (var text in new[] { r.Id, r.Kind, r.NameEn, r.NameBn, r.Area, PlaceText.Normalise($"{r.NameEn} {r.NameBn}") })
                {
                    await copy.WriteAsync(text, NpgsqlDbType.Text, cancellationToken);
                }
                await copy.WriteAsync(r.Point.Lng, NpgsqlDbType.Double, cancellationToken);
                await copy.WriteAsync(r.Point.Lat, NpgsqlDbType.Double, cancellationToken);
            }
            await copy.CompleteAsync(cancellationToken);
        }
        await Run(conn, "DELETE FROM customer.places", cancellationToken);
        var count = await Run(conn, """
            INSERT INTO customer.places (id, kind, name_en, name_bn, area, search_text, location)
            SELECT DISTINCT ON (id) id, kind, name_en, name_bn, area, search_text, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
            FROM places_load ORDER BY id
            """, cancellationToken);
        await Run(conn, $"""
            UPDATE customer.places p SET area = COALESCE((
                SELECT a.name_en FROM customer.places a
                WHERE a.kind = 'area' AND ST_DWithin(a.location, p.location, {AreaRadiusM})
                ORDER BY a.location <-> p.location LIMIT 1), '')
            WHERE p.area = '' AND p.kind <> 'area'
            """, cancellationToken);
        await tx.CommitAsync(cancellationToken);
        return count;
    }

    /// <summary>Whether any place is stored.</summary>
    public async Task<bool> Any(CancellationToken cancellationToken)
    {
        await using var conn = await data.OpenConnectionAsync(cancellationToken);
        await using var cmd = new NpgsqlCommand("SELECT EXISTS (SELECT 1 FROM customer.places)", conn);
        return (bool)(await cmd.ExecuteScalarAsync(cancellationToken))!;
    }

    /// <summary>The best places for <paramref name="query"/> (already normalised), nearest first among equals.</summary>
    public async Task<IReadOnlyList<PlaceRow>> Search(string query, GeoPoint? near, int limit, CancellationToken cancellationToken)
    {
        await using var conn = await data.OpenConnectionAsync(cancellationToken);
        await using var tx = await conn.BeginTransactionAsync(cancellationToken);
        await Run(conn, Threshold, cancellationToken);
        await using var cmd = new NpgsqlCommand("""
            SELECT id, kind, name_en, name_bn, area, ST_Y(location::geometry), ST_X(location::geometry) FROM customer.places
            WHERE @q <% search_text
            ORDER BY word_similarity(@q, search_text) DESC,
                array_position(ARRAY['area', 'street', 'place', 'address'], kind),
                CASE WHEN @lat::float8 IS NULL THEN 0 ELSE location <-> ST_SetSRID(ST_MakePoint(@lng::float8, @lat::float8), 4326)::geography END
            LIMIT @limit
            """, conn);
        cmd.Parameters.AddWithValue("q", query);
        cmd.Parameters.AddWithValue("lat", NpgsqlDbType.Double, (object?)near?.Lat ?? DBNull.Value);
        cmd.Parameters.AddWithValue("lng", NpgsqlDbType.Double, (object?)near?.Lng ?? DBNull.Value);
        cmd.Parameters.AddWithValue("limit", limit);
        return await Read(cmd, cancellationToken);
    }

    /// <summary>The nearest place within <see cref="ReverseRadiusM"/> of <paramref name="point"/>, streets and places first.</summary>
    public async Task<PlaceRow?> Nearest(GeoPoint point, CancellationToken cancellationToken)
    {
        await using var conn = await data.OpenConnectionAsync(cancellationToken);
        await using var cmd = new NpgsqlCommand($"""
            SELECT id, kind, name_en, name_bn, area, ST_Y(location::geometry), ST_X(location::geometry) FROM customer.places
            WHERE kind <> 'area' AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(@lng, @lat), 4326)::geography, {ReverseRadiusM})
            ORDER BY location <-> ST_SetSRID(ST_MakePoint(@lng, @lat), 4326)::geography LIMIT 1
            """, conn);
        cmd.Parameters.AddWithValue("lat", point.Lat);
        cmd.Parameters.AddWithValue("lng", point.Lng);
        return (await Read(cmd, cancellationToken)).FirstOrDefault();
    }

    private static async Task<IReadOnlyList<PlaceRow>> Read(NpgsqlCommand cmd, CancellationToken cancellationToken)
    {
        var rows = new List<PlaceRow>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new PlaceRow(reader.GetString(0), reader.GetString(1), reader.GetString(2), reader.GetString(3), reader.GetString(4),
                new GeoPoint { Lat = reader.GetDouble(5), Lng = reader.GetDouble(6) }));
        }
        return rows;
    }

    private static async Task<int> Run(NpgsqlConnection conn, string sql, CancellationToken cancellationToken)
    {
        await using var cmd = new NpgsqlCommand(sql, conn);
        return await cmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
