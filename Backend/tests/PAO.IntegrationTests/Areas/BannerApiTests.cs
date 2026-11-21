using System.Net;
using System.Text.Json;
using PAO.Lib.Areas.Catalog;
using PAO.Migrator;

namespace PAO.IntegrationTests.Areas;

public sealed class BannerApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private static readonly Guid Demo = Guid.Parse("5b7a1f2e-0c9d-4e3a-8b6f-2d1c0e9f8a71");
    private static readonly object Title = new { en = "Eid offer", bn = "ঈদ অফার" };
    private AreaApi api = null!;
    private string customer = string.Empty;
    private string admin = string.Empty;

    public async ValueTask InitializeAsync()
    {
        var output = new StringWriter();
        Assert.Equal(0, await new[] { "seed" }.RunMigrator(Hosts.Environment(database.Url), Hosts.Paths.Migrations, output,
            () => SeedCommand.Run(Hosts.Paths, Hosts.Environment(database.Url), output)));
        api = await AreaApi.Start(database.Url);
        customer = api.Token("customer");
        admin = api.Token("catalog_manager");
    }

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private static List<string> Ids(JsonElement body) => [.. body.GetProperty("banners").EnumerateArray().Select(b => b.GetProperty("id").GetString()!)];

    [Fact]
    public async Task The_seeded_demo_banner_shows_on_the_customer_home()
    {
        var home = await api.Call(HttpMethod.Get, "/v1/customer/banners", customer);
        Assert.Equal(HttpStatusCode.OK, home.Status);
        var demo = home.Body.GetProperty("banners").EnumerateArray().Single(b => b.GetProperty("id").GetString() == Demo.ToString());
        Assert.Equal("ঘরের সেবা, আপনার দোরগোড়ায়", demo.GetProperty("title").GetProperty("bn").GetString());
        Assert.True(demo.TryGetProperty("subtitle", out _));
        Assert.False(demo.TryGetProperty("imageUrl", out _));
        Assert.False(demo.TryGetProperty("serviceId", out _));
    }

    [Fact]
    public async Task Admins_add_edit_publish_and_remove_banners()
    {
        var service = SeedIds.For("service", "electrician");
        var created = await api.Call(HttpMethod.Post, "/v1/admin/catalog/banners", admin,
            new { title = Title, imageUrl = "https://cdn.example.com/eid.jpg", serviceId = service, sortOrder = -1 });
        Assert.Equal(HttpStatusCode.Created, created.Status);
        var id = created.Body.GetProperty("id").GetString()!;
        Assert.False(created.Body.GetProperty("published").GetBoolean());
        Assert.DoesNotContain(id, Ids((await api.Call(HttpMethod.Get, "/v1/customer/banners", customer)).Body));
        Assert.Equal(id, Ids((await api.Call(HttpMethod.Get, "/v1/admin/catalog/banners", admin)).Body)[0]);

        var updated = await api.Call(HttpMethod.Put, $"/v1/admin/catalog/banners/{id}", admin,
            new { title = Title, subtitle = Title, serviceId = service, sortOrder = -1, published = true });
        Assert.Equal(HttpStatusCode.OK, updated.Status);
        var home = await api.Call(HttpMethod.Get, "/v1/customer/banners", customer);
        Assert.Equal(id, Ids(home.Body)[0]);
        Assert.Equal(service.ToString(), home.Body.GetProperty("banners")[0].GetProperty("serviceId").GetString());
        Assert.False(home.Body.GetProperty("banners")[0].TryGetProperty("imageUrl", out _));

        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Delete, $"/v1/admin/catalog/banners/{id}", admin)).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Delete, $"/v1/admin/catalog/banners/{id}", admin)).Status);
        Assert.DoesNotContain(id, Ids((await api.Call(HttpMethod.Get, "/v1/admin/catalog/banners", admin)).Body));
    }

    [Fact]
    public async Task Bad_banners_are_refused()
    {
        var missing = Guid.NewGuid();
        var cases = new (HttpMethod Method, string Path, object Body, HttpStatusCode Status)[]
        {
            (HttpMethod.Post, "/v1/admin/catalog/banners", new { title = new { en = "x", bn = " " } }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/banners", new { title = Title, subtitle = new { en = "x", bn = "" } }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/banners", new { title = Title, imageUrl = "http://plain.example.com/a.jpg" }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/banners", new { title = Title, imageUrl = "not a url" }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/banners", new { title = Title, imageUrl = "https://x.example.com/" + new string('a', 500) }, HttpStatusCode.UnprocessableEntity),
            (HttpMethod.Post, "/v1/admin/catalog/banners", new { title = Title, serviceId = missing }, HttpStatusCode.NotFound),
            (HttpMethod.Put, $"/v1/admin/catalog/banners/{missing}", new { title = Title }, HttpStatusCode.NotFound),
        };
        foreach (var (method, path, body, status) in cases)
        {
            Assert.Equal(status, (await api.Call(method, path, admin, body)).Status);
        }
        Assert.Equal(HttpStatusCode.Forbidden, (await api.Call(HttpMethod.Get, "/v1/admin/catalog/banners", customer)).Status);
    }
}
