using System.Net;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.EF;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.Migrator;

namespace PAO.IntegrationTests.Areas;

public sealed class CatalogApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private static readonly object Name = new { en = "Cleaning", bn = "পরিষ্কার" };
    private AreaApi api = null!;
    private string customer = string.Empty;
    private string admin = string.Empty;

    public async ValueTask InitializeAsync()
    {
        var output = new StringWriter();
        Assert.Equal(0, await new[] { "seed" }.RunMigrator(Hosts.Environment(database.Url), Hosts.Paths.Migrations, output,
            () => SeedCommand.Run(Hosts.Paths, Hosts.Environment(database.Url), output)));
        Assert.Contains("migrate seed: 7 categories", output.ToString(), StringComparison.Ordinal);
        api = await AreaApi.Start(database.Url);
        customer = api.Token("customer");
        admin = api.Token("catalog_manager");
    }

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private ICatalogSharedService Contract(IServiceScope scope) => scope.ServiceProvider.GetRequiredService<ICatalogSharedService>();

    private static List<string> Ids(JsonElement body, string name) => [.. body.GetProperty(name).EnumerateArray().Select(e => e.GetProperty("id").GetString()!)];

    [Fact]
    public async Task Customers_browse_search_and_open_a_service()
    {
        var tree = await api.Call(HttpMethod.Get, "/v1/customer/catalog", customer);
        Assert.Equal(HttpStatusCode.OK, tree.Status);
        Assert.Equal(7, tree.Body.GetProperty("categories").GetArrayLength());
        Assert.Equal(7, (await api.Call(HttpMethod.Get, "/v1/customer/catalog", customer)).Body.GetProperty("categories").GetArrayLength());
        var searches = new Dictionary<string, Guid>
        {
            ["fan"] = SeedIds.For("sub-service", "fan-install"),
            ["ফ্যান"] = SeedIds.For("sub-service", "fan-install"),
            ["plumbr"] = SeedIds.For("service", "plumber"),
            ["স্যালন"] = SeedIds.For("service", "home-salon"),
        };
        foreach (var (q, id) in searches)
        {
            var found = await api.Call(HttpMethod.Get, $"/v1/customer/catalog/search?q={Uri.EscapeDataString(q)}", customer);
            Assert.Contains(id.ToString(), Ids(found.Body, "services").Concat(Ids(found.Body, "subServices")));
        }
        var electrician = await api.Call(HttpMethod.Get, $"/v1/customer/services/{SeedIds.For("service", "electrician")}", customer);
        Assert.Equal(5, electrician.Body.GetProperty("subServices").GetArrayLength());
        Assert.False(electrician.Body.GetProperty("subServices")[0].TryGetProperty("description", out _));
        var unknown = await api.Call(HttpMethod.Get, $"/v1/customer/services/{Guid.NewGuid()}", customer);
        Assert.Equal(HttpStatusCode.NotFound, unknown.Status);
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Get, "/v1/provider/catalog", api.Token("provider"))).Status);
    }

    [Fact]
    public async Task Admins_edit_the_catalog_and_version_prices()
    {
        var cat = await api.Call(HttpMethod.Post, "/v1/admin/catalog/categories", admin, new { name = Name, iconKey = "broom", published = true });
        Assert.Equal(HttpStatusCode.Created, cat.Status);
        var categoryId = cat.Body.GetProperty("id").GetString();
        var serviceBody = new { categoryId, name = Name, iconKey = "broom", serviceModel = "on_demand", requiredLevel = 1, searchRadiusM = 5000, published = true, level2Checklist = new[] { Name } };
        var svc = await api.Call(HttpMethod.Post, "/v1/admin/catalog/services", admin, serviceBody);
        Assert.Equal(HttpStatusCode.Created, svc.Status);
        var serviceId = svc.Body.GetProperty("id").GetString();
        var subBody = new { serviceId, name = Name, unit = "job", initialPrice = 100_000, published = true, description = Name, inclusions = new[] { Name }, exclusions = Array.Empty<object>() };
        var sub = await api.Call(HttpMethod.Post, "/v1/admin/catalog/sub-services", admin, subBody);
        Assert.Equal(HttpStatusCode.Created, sub.Status);
        var subId = Guid.Parse(sub.Body.GetProperty("id").GetString()!);
        using var scope = api.Services.CreateScope();
        var before = await Contract(scope).GetPriceSnapshot(subId, CancellationToken.None);
        Assert.Equal(100_000, before.AmountPaisa);
        var prices = $"/v1/admin/catalog/sub-services/{subId}/prices";
        var changed = await api.Call(HttpMethod.Post, prices, admin, new { amount = 120_000 });
        Assert.Equal(HttpStatusCode.Created, changed.Status);
        Assert.EndsWith("Z", changed.Body.GetProperty("effectiveFrom").GetString(), StringComparison.Ordinal);
        var after = await Contract(api.Services.CreateScope()).GetPriceSnapshot(subId, CancellationToken.None);
        Assert.Equal(120_000, after.AmountPaisa);
        Assert.NotEqual(before.PriceVersionId, after.PriceVersionId);
        Assert.Equal(2, (await api.Call(HttpMethod.Get, prices, admin)).Body.GetProperty("items").GetArrayLength());
        await UpdatesKeepTheTree(categoryId!, serviceId!, subId, serviceBody, subBody);
    }

    private async Task UpdatesKeepTheTree(string categoryId, string serviceId, Guid subId, object serviceBody, object subBody)
    {
        var updates = new (string Path, object Body)[]
        {
            ($"/v1/admin/catalog/categories/{categoryId}", new { name = Name, iconKey = "broom", published = false }),
            ($"/v1/admin/catalog/services/{serviceId}", serviceBody),
            ($"/v1/admin/catalog/sub-services/{subId}", subBody),
        };
        foreach (var (path, body) in updates)
        {
            Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, path, admin, body)).Status);
        }
        Assert.Equal(8, (await api.Call(HttpMethod.Get, "/v1/admin/catalog", admin)).Body.GetProperty("categories").GetArrayLength());
        Assert.Equal(7, (await api.Call(HttpMethod.Get, "/v1/customer/catalog", customer)).Body.GetProperty("categories").GetArrayLength());
        var db = api.Services.CreateScope().ServiceProvider.GetRequiredService<PaoDbContext>();
        var events = await db.Database.SqlQuery<string>($"""SELECT event_name AS "Value" FROM catalog.outbox""").ToListAsync();
        Assert.Contains(CatalogEvents.PriceChanged, events);
        Assert.Contains(CatalogEvents.CatalogChanged, events);
    }

    [Fact]
    public async Task Missing_and_invalid_items_are_refused()
    {
        var missing = Guid.NewGuid();
        var service = new { categoryId = missing, name = Name, iconKey = "x", serviceModel = "on_demand", requiredLevel = 1, searchRadiusM = 5000 };
        var cases = new (HttpMethod Method, string Path, object? Body, HttpStatusCode Status)[]
        {
            (HttpMethod.Put, $"/v1/admin/catalog/categories/{missing}", new { name = Name, iconKey = "x", sortOrder = 3 }, HttpStatusCode.NotFound),
            (HttpMethod.Post, "/v1/admin/catalog/categories", new { name = new { en = "x", bn = " " }, iconKey = "x" }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Put, $"/v1/admin/catalog/services/{missing}", service, HttpStatusCode.NotFound),
            (HttpMethod.Put, $"/v1/admin/catalog/services/{missing}", service with { categoryId = SeedIds.For("category", "electrical") }, HttpStatusCode.NotFound),
            (HttpMethod.Post, "/v1/admin/catalog/services", service, HttpStatusCode.NotFound),
            (HttpMethod.Post, "/v1/admin/catalog/services", new { service.categoryId, name = Name, iconKey = "x", serviceModel = "on_demand", requiredLevel = 1, searchRadiusM = 5000, requiresLevel2 = true }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/sub-services", new { serviceId = missing, name = Name, unit = "job", initialPrice = 1, maxQuantity = 0 }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/sub-services", new { serviceId = missing, name = Name, unit = "job", initialPrice = 1 }, HttpStatusCode.NotFound),
            (HttpMethod.Put, $"/v1/admin/catalog/sub-services/{missing}", new { serviceId = missing, name = Name, unit = "job" }, HttpStatusCode.NotFound),
            (HttpMethod.Put, $"/v1/admin/catalog/sub-services/{missing}", new { serviceId = missing, name = new { en = " ", bn = "x" }, unit = "job" }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, $"/v1/admin/catalog/sub-services/{missing}/prices", new { amount = 1 }, HttpStatusCode.NotFound),
            (HttpMethod.Get, $"/v1/admin/catalog/sub-services/{missing}/prices", null, HttpStatusCode.NotFound),
        };
        foreach (var (method, path, body, status) in cases)
        {
            Assert.Equal((method, path, status), (method, path, (await api.Call(method, path, admin, body)).Status));
        }
        var noPrice = await api.Call(HttpMethod.Post, "/v1/admin/catalog/sub-services", admin, new { serviceId = missing, name = Name, unit = "job" });
        Assert.Equal("VALIDATION_FAILED", noPrice.Body.GetProperty("error").GetProperty("code").GetString());
        Assert.Equal("amount", noPrice.Body.GetProperty("error").GetProperty("details").GetProperty("field").GetString());
        using var scope = api.Services.CreateScope();
        Assert.True(DomainException.Is(await Assert.ThrowsAsync<DomainException>(() => Contract(scope).GetService(Guid.NewGuid(), CancellationToken.None)), CatalogErrors.ServiceNotFound));
        Assert.True(DomainException.Is(await Assert.ThrowsAsync<DomainException>(() => Contract(scope).GetPriceSnapshot(Guid.NewGuid(), CancellationToken.None)), CatalogErrors.SubServiceNotFound));
    }

    [Fact]
    public async Task The_contract_answers_from_the_seeded_catalog()
    {
        using var scope = api.Services.CreateScope();
        var salon = await Contract(scope).GetService(SeedIds.For("service", "home-salon"), CancellationToken.None);
        Assert.True(salon.WomenProvidersOnly);
        Assert.Equal(ServiceModel.OnDemand, salon.Model);
        Assert.Equal(2, salon.Level2Checklist.Count);
        Assert.Equal(7, (await Contract(scope).ListServices(CancellationToken.None)).Count);
    }

    [Fact]
    public async Task A_redis_failure_only_costs_a_database_read()
    {
        var options = StackExchange.Redis.ConfigurationOptions.Parse("127.0.0.1:1,abortConnect=false,connectTimeout=100,syncTimeout=200,asyncTimeout=200,connectRetry=0");
        using var broken = await StackExchange.Redis.ConnectionMultiplexer.ConnectAsync(options);
        using var scope = api.Services.CreateScope();
        var tree = new CatalogTreeService(
            scope.ServiceProvider.GetRequiredService<CatalogRepository>(), new JsonCache(broken), scope.ServiceProvider.GetRequiredService<RedisKeys>(),
            NullLogger<CatalogTreeService>.Instance);
        Assert.Equal(7, (await tree.Published(CancellationToken.None)).Categories.Count);
    }
}
