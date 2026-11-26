using System.Net;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Catalog.Features.Icons.Commands;
using PAO.Core.Areas.Catalog.Services.Icons;
using PAO.Infrastructure.Storage;
using PAO.Lib.Areas.Catalog;
using PAO.Migrator;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

public sealed class IconApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private const string Svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" onload="alert(1)"><script>alert(1)</script><path d="M3 8h8"/></svg>""";
    private static readonly object Name = new { en = "Plumbing", bn = "প্লাম্বিং" };
    private AreaApi api = null!;
    private string admin = string.Empty;
    private string customer = string.Empty;

    private sealed class Stub(HttpResponseMessage answer) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) => Task.FromResult(answer);
    }

    public async ValueTask InitializeAsync()
    {
        var output = new StringWriter();
        Assert.Equal(0, await new[] { "seed" }.RunMigrator(Hosts.Environment(database.Url), Hosts.Paths.Migrations, output,
            () => SeedCommand.Run(Hosts.Paths, Hosts.Environment(database.Url), output)));
        var storage = TestSettings.Create().Storage;
        using (var store = new ObjectStore(storage))
        {
            await store.EnsureBucket(storage.BucketPublic, CancellationToken.None);
            await store.AllowPublicRead(storage.BucketPublic, CancellationToken.None);
        }
        api = await AreaApi.Start(database.Url);
        admin = api.Token("catalog_manager");
        customer = api.Token("customer");
    }

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private Task<(HttpStatusCode Status, System.Text.Json.JsonElement Body)> Upload(string type, byte[] file) =>
        api.Call(HttpMethod.Post, "/v1/admin/catalog/icons", admin, new { contentType = type, data = Convert.ToBase64String(file) });

    private static string Reason(System.Text.Json.JsonElement body) =>
        body.GetProperty("error").GetProperty("details").GetProperty("reason").GetString()!;

    [Fact]
    public async Task Admins_see_the_library_the_apps_ship()
    {
        var library = await api.Call(HttpMethod.Get, "/v1/admin/catalog/icons", admin);
        Assert.Equal(HttpStatusCode.OK, library.Status);
        Assert.Equal(IconLibrary.Keys, library.Body.GetProperty("keys").EnumerateArray().Select(k => k.GetString()!));
        Assert.Equal(HttpStatusCode.Forbidden, (await api.Call(HttpMethod.Get, "/v1/admin/catalog/icons", customer)).Status);
    }

    [Fact]
    public async Task An_uploaded_svg_is_cleaned_readable_by_anyone_and_shown_on_its_category()
    {
        var uploaded = await Upload(IconTypes.Svg, Encoding.UTF8.GetBytes(Svg));
        Assert.Equal(HttpStatusCode.Created, uploaded.Status);
        var url = uploaded.Body.GetProperty("iconUrl").GetString()!;
        using (var anonymous = new HttpClient())
        {
            var stored = await anonymous.GetStringAsync(url);
            Assert.Contains("<path d=\"M3 8h8\"", stored, StringComparison.Ordinal);
            Assert.DoesNotContain("script", stored, StringComparison.Ordinal);
            Assert.DoesNotContain("onload", stored, StringComparison.Ordinal);
        }
        var category = SeedIds.For("category", "plumbing");
        var saved = await api.Call(HttpMethod.Put, $"/v1/admin/catalog/categories/{category}", admin,
            new { name = Name, iconKey = "plumbing", iconUrl = url, published = true });
        Assert.Equal(HttpStatusCode.OK, saved.Status);
        var tree = await api.Call(HttpMethod.Get, "/v1/customer/catalog", customer);
        var shown = tree.Body.GetProperty("categories").EnumerateArray().Single(c => c.GetProperty("id").GetString() == category.ToString());
        Assert.Equal(url, shown.GetProperty("iconUrl").GetString());
        Assert.All(shown.GetProperty("services").EnumerateArray(), s => Assert.False(s.TryGetProperty("iconUrl", out _)));
    }

    [Fact]
    public async Task Png_and_webp_icons_are_checked_before_they_are_stored()
    {
        var png = await Upload(IconTypes.Png, Png(128, 128, 6));
        Assert.Equal((HttpStatusCode.Created, IconTypes.Png), (png.Status, png.Body.GetProperty("contentType").GetString()));
        Assert.EndsWith(".png", png.Body.GetProperty("iconUrl").GetString(), StringComparison.Ordinal);
        Assert.Equal("icon_not_square", Reason((await Upload(IconTypes.Png, Png(128, 96, 6))).Body));
        Assert.Equal("icon_too_small", Reason((await Upload(IconTypes.Png, Png(48, 48, 6))).Body));
        Assert.Equal("icon_opaque", Reason((await Upload(IconTypes.Png, Png(128, 128, 2))).Body));
        Assert.Equal("icon_unreadable", Reason((await Upload(IconTypes.Webp, Png(128, 128, 6))).Body));
        Assert.Equal("icon_unreadable", Reason((await Upload(IconTypes.Svg, Encoding.UTF8.GetBytes("<html/>"))).Body));
        Assert.Equal("icon_too_large", Reason((await Upload(IconTypes.Svg, new byte[IconTypes.MaxSvgBytes + 1])).Body));
    }

    [Fact]
    public async Task Links_to_our_network_and_icons_we_do_not_hold_are_refused()
    {
        var local = await api.Call(HttpMethod.Post, "/v1/admin/catalog/icons/from-link", admin, new { url = "https://127.0.0.1:9/icon.svg" });
        Assert.Equal((HttpStatusCode.UnprocessableEntity, "icon_link_failed"), (local.Status, Reason(local.Body)));
        var plain = await api.Call(HttpMethod.Post, "/v1/admin/catalog/icons/from-link", admin, new { url = "http://example.com/icon.svg" });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, plain.Status);
        var foreign = await api.Call(HttpMethod.Put, $"/v1/admin/catalog/categories/{SeedIds.For("category", "plumbing")}", admin,
            new { name = Name, iconKey = "plumbing", iconUrl = "https://evil.example/catalog-icons/a.svg" });
        Assert.Equal("iconUrl", foreign.Body.GetProperty("error").GetProperty("details").GetProperty("field").GetString());
        var service = await api.Call(HttpMethod.Put, $"/v1/admin/catalog/services/{SeedIds.For("service", "plumber")}", admin, new
        {
            categoryId = SeedIds.For("category", "plumbing"),
            name = Name,
            iconKey = "plumbing",
            iconUrl = "https://evil.example/x.svg",
            serviceModel = ServiceModel.OnDemand,
            requiredLevel = 1,
            searchRadiusM = 5000,
        });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, service.Status);
    }

    [Fact]
    public async Task A_downloaded_icon_is_stored_like_an_upload()
    {
        var content = new ByteArrayContent(Encoding.UTF8.GetBytes(Svg));
        content.Headers.ContentType = new MediaTypeHeaderValue(IconTypes.Svg);
        using var scope = api.Services.CreateScope();
        var handler = new AddIconFromLinkHandler(
            new IconFetcher(new HttpClient(new Stub(new HttpResponseMessage(HttpStatusCode.OK) { Content = content }))),
            scope.ServiceProvider.GetRequiredService<IconFiles>());
        var icon = await handler.Handle(new AddIconFromLink(new IconLink { Url = "https://cdn.example/tap.svg" }, Guid.NewGuid()), CancellationToken.None);
        Assert.EndsWith(".svg", icon.IconUrl, StringComparison.Ordinal);
        using var anonymous = new HttpClient();
        Assert.DoesNotContain("script", await anonymous.GetStringAsync(icon.IconUrl), StringComparison.Ordinal);
    }

    private static byte[] Png(int width, int height, byte colourType)
    {
        var file = new byte[45];
        new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52 }.CopyTo(file, 0);
        System.Buffers.Binary.BinaryPrimitives.WriteInt32BigEndian(file.AsSpan(16), width);
        System.Buffers.Binary.BinaryPrimitives.WriteInt32BigEndian(file.AsSpan(20), height);
        file[24] = 8;
        file[25] = colourType;
        Encoding.ASCII.GetBytes("IEND").CopyTo(file, 37);
        return file;
    }
}
