using System.Net;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Http.OpenApi;
using PAO.TestKit;

namespace PAO.IntegrationTests.Identity;

/// <summary>RBAC over the whole contract: answers other than 403 are whatever the route does with an empty request.</summary>
public sealed partial class RbacContractTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private WebApplication app = null!;
    private HttpClient client = null!;

    public async ValueTask InitializeAsync()
    {
        app = await Hosts.Api(database.Url);
        client = app.GetTestClient();
    }

    public async ValueTask DisposeAsync() => await app.DisposeAsync();

    private IEnumerable<(string Method, string Path, string Permission)> Protected() =>
        app.Services.GetRequiredService<SpecRoutes>().Operations
            .Where(op => op.Permission is not (null or "public" or "authenticated"))
            .Select(op => (op.Method.ToUpperInvariant(), Fill(op.PathTemplate), op.Permission!));

    private static string Fill(string path) => Placeholder().Replace(
        path.Replace("{role}", "customer", StringComparison.Ordinal).Replace("{itemType}", "nid", StringComparison.Ordinal)
            .Replace("{key}", "booking.accept_timeout_asap_seconds", StringComparison.Ordinal),
        _ => Guid.NewGuid().ToString());

    // A fresh subject per call keeps the per-user rate limit out of the way.
    private async Task<bool> Forbidden(string method, string path, string[] roles)
    {
        using var request = Hosts.Request(new HttpMethod(method), path, Hosts.Token(app.Services, roles));
        var status = (await client.SendAsync(request)).StatusCode;
        Assert.NotEqual((method, path, HttpStatusCode.InternalServerError), (method, path, status));
        return status == HttpStatusCode.Forbidden;
    }

    [Fact]
    public async Task Every_protected_route_refuses_a_token_without_its_permission()
    {
        var ops = Protected().ToList();
        Assert.True(ops.Count >= 100);
        foreach (var (method, path, _) in ops)
        {
            Assert.Equal((method, path, true), (method, path, await Forbidden(method, path, [])));
        }
    }

    [Fact]
    public async Task Every_role_reaches_exactly_its_seeded_permissions()
    {
        await using var connection = await TestDatabases.Open(database.Url);
        await using var command = new Npgsql.NpgsqlCommand("SELECT role, permission FROM identity.role_permissions", connection);
        var grants = new Dictionary<string, HashSet<string>>();
        await using (var reader = await command.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                var role = reader.GetString(0);
                grants[role] = grants.GetValueOrDefault(role) ?? [];
                grants[role].Add(reader.GetString(1));
            }
        }
        Assert.Equal(6, grants.Count);
        foreach (var (role, has) in grants)
        {
            foreach (var (method, path, permission) in Protected())
            {
                Assert.Equal((role, method, path, !has.Contains(permission)), (role, method, path, await Forbidden(method, path, [role])));
            }
        }
    }

    [GeneratedRegex(@"\{[a-zA-Z]+\}")]
    private static partial Regex Placeholder();
}
