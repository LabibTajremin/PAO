using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using NpgsqlTypes;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Hosting;

namespace PAO.Migrator;

/// <summary>One encrypted column and the uuid key that finds its row.</summary>
public sealed record EncryptedColumn(string Table, string Key, string Column);

/// <summary>
/// `migrate reencrypt`: rewrites every encrypted field under DATA_ENCRYPTION_KEY, so a key
/// in DATA_ENCRYPTION_PREVIOUS_KEYS no longer encrypts anything (docs/runbooks/rotate-data-key.md).
/// Rows already under the current key are left alone, so the command can be repeated.
/// Lookup hashes are not touched: they stay on the original key (<see cref="DataCipher"/>).
/// </summary>
public static class ReencryptCommand
{
    /// <summary>Every column <see cref="DataCipher"/> writes.</summary>
    public static readonly IReadOnlyList<EncryptedColumn> Columns =
    [
        new("identity.admin_credentials", "account_id", "totp_secret_enc"),
        new("verification.nid_records", "provider_id", "nid_ciphertext"),
    ];

    /// <summary>Re-encrypts with the configuration of `environment`; returns the exit code.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, TextWriter output)
    {
        using var host = SeedCommand.BuildHost(paths, environment);
        var dataSource = host.Services.GetRequiredService<NpgsqlDataSource>();
        var cipher = host.Services.GetRequiredService<DataCipher>();
        await using var connection = await dataSource.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();
        foreach (var column in Columns)
        {
            var changed = await Rewrite(connection, column, cipher);
            await output.WriteLineAsync($"migrate reencrypt: {column.Table}.{column.Column}: {changed} rows");
        }
        await transaction.CommitAsync();
        return 0;
    }

    private static async Task<int> Rewrite(NpgsqlConnection connection, EncryptedColumn column, DataCipher cipher)
    {
        var ids = new List<Guid>();
        var values = new List<byte[]>();
        await using (var select = new NpgsqlCommand($"SELECT {column.Key}, {column.Column} FROM {column.Table} WHERE {column.Column} IS NOT NULL FOR UPDATE", connection))
        await using (var reader = await select.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                if (cipher.Reencrypt((byte[])reader[1]) is { } fresh)
                {
                    ids.Add(reader.GetGuid(0));
                    values.Add(fresh);
                }
            }
        }
        await using var update = new NpgsqlCommand(
            $"UPDATE {column.Table} t SET {column.Column} = v.value FROM unnest(@ids, @values) AS v(id, value) WHERE t.{column.Key} = v.id", connection);
        update.Parameters.Add(new NpgsqlParameter("ids", NpgsqlDbType.Array | NpgsqlDbType.Uuid) { Value = ids.ToArray() });
        update.Parameters.Add(new NpgsqlParameter("values", NpgsqlDbType.Array | NpgsqlDbType.Bytea) { Value = values.ToArray() });
        return await update.ExecuteNonQueryAsync();
    }
}
