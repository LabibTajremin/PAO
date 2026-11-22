using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.EF;
using PAO.Migrator;

namespace PAO.IntegrationTests.Areas;

public sealed class AppearanceApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private const string Hero = "customer.signin.hero";
    private AreaApi api = null!;
    private string admin = string.Empty;
    private string viewer = string.Empty;

    public async ValueTask InitializeAsync()
    {
        Assert.Contains("migrate seed: 16 artwork slots", await Seed(), StringComparison.Ordinal);
        api = await AreaApi.Start(database.Url);
        admin = api.Token("super_admin");
        viewer = api.Token("catalog_manager");
    }

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private async Task<string> Seed()
    {
        var output = new StringWriter();
        Assert.Equal(0, await new[] { "seed" }.RunMigrator(Hosts.Environment(database.Url), Hosts.Paths.Migrations, output,
            () => SeedCommand.Run(Hosts.Paths, Hosts.Environment(database.Url), output)));
        return output.ToString();
    }

    private async Task<HttpResponseMessage> Config(string app, string? etag = null)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, $"/v1/app-config?app={app}");
        if (etag is not null)
        {
            request.Headers.TryAddWithoutValidation("If-None-Match", etag);
        }
        return await api.Client.SendAsync(request);
    }

    private static async Task<JsonElement> Json(HttpResponseMessage response) =>
        JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement;

    private static JsonElement Image(JsonElement config, string key) =>
        config.GetProperty("artwork").EnumerateArray().Single(a => a.GetProperty("key").GetString() == key);

    private Task<(HttpStatusCode Status, JsonElement Body)> Upload(string key, string type, byte[] file) =>
        api.Call(HttpMethod.Put, $"/v1/admin/artwork/{key}", admin, new { contentType = type, data = Convert.ToBase64String(file) });

    private static byte[] Svg(int width, int height) =>
        Encoding.UTF8.GetBytes($"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 {width} {height}' onload='x()'><circle r='9'/></svg>");

    [Fact]
    public async Task Apps_read_the_tagline_and_their_seeded_artwork_without_signing_in()
    {
        var customer = await Config("customer");
        Assert.Equal(HttpStatusCode.OK, customer.StatusCode);
        var body = await Json(customer);
        Assert.Equal("যা চাও, তাই PAO", body.GetProperty("tagline").GetProperty("bn").GetString());
        Assert.Equal(1, Image(body, Hero).GetProperty("version").GetInt32());
        Assert.DoesNotContain(body.GetProperty("artwork").EnumerateArray(), a => a.GetProperty("key").GetString()!.StartsWith("partner.", StringComparison.Ordinal));
        var etag = customer.Headers.ETag!.ToString();
        Assert.Equal(HttpStatusCode.NotModified, (await Config("customer", etag)).StatusCode);
        using (var anonymous = new HttpClient())
        {
            Assert.Contains("<svg", await anonymous.GetStringAsync(Image(body, Hero).GetProperty("url").GetString()), StringComparison.Ordinal);
        }
        Assert.Contains("offline", (await Json(await Config("partner"))).GetProperty("artwork").ToString(), StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Config("everyone")).StatusCode);
        Assert.Contains("migrate seed: 16 artwork slots", await Seed(), StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.NotModified, (await Config("customer", etag)).StatusCode);
    }

    [Fact]
    public async Task An_uploaded_image_replaces_the_seed_until_it_is_reset()
    {
        var list = await api.Call(HttpMethod.Get, "/v1/admin/artwork", viewer);
        Assert.Equal(16, list.Body.GetProperty("slots").GetArrayLength());
        var forbidden = await api.Call(HttpMethod.Put, $"/v1/admin/artwork/{Hero}", viewer,
            new { contentType = "image/svg+xml", data = Convert.ToBase64String(Svg(1170, 1200)) });
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.Status);
        var uploaded = await Upload("offline", "image/svg+xml", Svg(720, 540));
        Assert.Equal((true, 2), (uploaded.Body.GetProperty("replaced").GetBoolean(), uploaded.Body.GetProperty("version").GetInt32()));
        var url = uploaded.Body.GetProperty("url").GetString()!;
        using (var anonymous = new HttpClient())
        {
            Assert.DoesNotContain("onload", await anonymous.GetStringAsync(url), StringComparison.Ordinal);
        }
        await Seed();
        Assert.Equal(url, Image(await Json(await Config("customer")), "offline").GetProperty("url").GetString());
        var reset = await api.Call(HttpMethod.Delete, "/v1/admin/artwork/offline", admin);
        Assert.Equal((false, 3), (reset.Body.GetProperty("replaced").GetBoolean(), reset.Body.GetProperty("version").GetInt32()));
        Assert.NotEqual(url, reset.Body.GetProperty("url").GetString());
    }

    [Fact]
    public async Task Artwork_that_does_not_fit_its_slot_is_refused_with_the_expected_size()
    {
        var wrong = await Upload(Hero, "image/svg+xml", Svg(1600, 1200));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, wrong.Status);
        Assert.Equal("1170x1200", wrong.Body.GetProperty("error").GetProperty("details").GetProperty("expected").GetString());
        var garbage = await api.Call(HttpMethod.Put, $"/v1/admin/artwork/{Hero}", admin, new { contentType = "image/svg+xml", data = "!!!!" });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, garbage.Status);
        Assert.Equal(HttpStatusCode.NotFound, (await Upload("no.such", "image/svg+xml", Svg(1, 1))).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Delete, "/v1/admin/artwork/no.such", admin)).Status);
    }

    [Fact]
    public async Task A_slot_without_a_seed_falls_back_to_the_bundled_image_on_reset()
    {
        using (var scope = api.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<PaoDbContext>().Database
                .ExecuteSqlAsync($"DELETE FROM admin.artwork_slots WHERE key = 'success.job'");
        }
        var reset = await api.Call(HttpMethod.Delete, "/v1/admin/artwork/success.job", admin);
        Assert.Equal((1, false), (reset.Body.GetProperty("version").GetInt32(), reset.Body.TryGetProperty("url", out _)));
        Assert.DoesNotContain("success.job", (await Json(await Config("partner"))).GetProperty("artwork").ToString(), StringComparison.Ordinal);
    }

    [Fact]
    public async Task Admins_edit_the_tagline_within_its_limits()
    {
        var updated = await api.Call(HttpMethod.Put, "/v1/admin/settings/brand.tagline", admin,
            new { value = """{"en":"Need it? PAO it.","bn":"চাইলেই PAO"}""" });
        Assert.Equal(HttpStatusCode.OK, updated.Status);
        Assert.Equal("Need it? PAO it.", (await Json(await Config("admin"))).GetProperty("tagline").GetProperty("en").GetString());
        var tooLong = await api.Call(HttpMethod.Put, "/v1/admin/settings/brand.tagline", admin,
            new { value = $$"""{"en":"{{new string('x', 41)}}","bn":"x"}""" });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, tooLong.Status);
    }
}
