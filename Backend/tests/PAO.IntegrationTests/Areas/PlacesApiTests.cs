using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using PAO.Core.Areas.Customer.Features.Places.Queries;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Customer;
using PAO.Migrator;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

/// <summary>The OpenStreetMap place search and reverse lookup over the seeded Dhaka sample (ADR-0042).</summary>
public sealed class PlacesApiTests : IAsyncLifetime
{
    private PeopleApi api = null!;
    private string url = string.Empty;
    private string token = string.Empty;

    public async ValueTask InitializeAsync()
    {
        api = await PeopleApi.Start(url = await TestDatabases.CreateMigrated());
        token = (await api.SignIn("01712345671", "customer")).Token;
    }

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private async Task<JsonElement[]> Search(string query) =>
        [.. (await api.Call(HttpMethod.Get, "/v1/places/search?" + query, token)).Body.GetProperty("items").EnumerateArray()];

    private static string Title(JsonElement place) => place.GetProperty("title").GetString()!;

    [Fact]
    public async Task Search_matches_english_bangla_and_bangla_digits_with_areas_first()
    {
        var dhanmondi = await Search("q=dhanmondi");
        Assert.Equal(("Dhanmondi", "area"), (Title(dhanmondi[0]), dhanmondi[0].GetProperty("kind").GetString()));
        Assert.Contains(dhanmondi, p => Title(p) == "Road 27 Dhanmondi");
        Assert.Equal("ধানমন্ডি", Title((await Search("q=ধানমন্ডি&lang=bn"))[0]));
        Assert.Equal("Road 27 Dhanmondi", Title((await Search("q=রোড ২৭"))[0]));
        Assert.Equal("Road 27 Dhanmondi", Title((await Search("q=Dhanmondi 27"))[0]));
        Assert.Equal("Gulshan 2", Title((await Search("q=গুলশান ২"))[0]));
        var hospital = (await Search("q=square hospital"))[0];
        Assert.Equal(("Dhanmondi", 23.7530), (hospital.GetProperty("area").GetString(), hospital.GetProperty("location").GetProperty("lat").GetDouble()));
        Assert.Equal("Panthapath", (await Search("q=bashundhara"))[0].GetProperty("area").GetString());
        Assert.Equal("North End Coffee Roasters", Title((await Search("q=north end&lang=bn"))[0]));
        Assert.Equal("address", (await Search("q=12, road 7"))[0].GetProperty("kind").GetString());
        Assert.Equal("Gulshan Avenue", Title((await Search("q=gulshan avenue&lat=23.79&lng=90.41"))[0]));
        Assert.Empty(await Search("q=chittagong port"));
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await api.Call(HttpMethod.Get, "/v1/places/search?q=%20a%20", token)).Body));
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.Call(HttpMethod.Get, "/v1/places/search?q=gulshan", null)).Status);
    }

    [Fact]
    public async Task Reverse_names_the_nearest_place_inside_the_launch_area_only()
    {
        var near = await api.Call(HttpMethod.Get, "/v1/places/reverse?lat=23.7531&lng=90.3817", token);
        Assert.Equal("Square Hospital", Title(near.Body));
        Assert.Equal("স্কয়ার হাসপাতাল", Title((await api.Call(HttpMethod.Get, "/v1/places/reverse?lat=23.7531&lng=90.3817&lang=bn", token)).Body));
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, "/v1/places/reverse?lat=23.82&lng=90.43", token)).Status);
        await api.SetSetting("service_area.geojson", """{"type":"Polygon","coordinates":[[[90.3,23.7],[90.5,23.7],[90.5,23.9],[90.3,23.9],[90.3,23.7]]]}""");
        var outside = await api.Call(HttpMethod.Get, "/v1/places/reverse?lat=22.33&lng=91.81", token);
        Assert.Equal("OUTSIDE_SERVICE_AREA", PeopleApi.Code(outside.Body));
    }

    [Fact]
    public async Task An_import_replaces_every_place_and_answers_are_cached_for_a_day()
    {
        Assert.Equal("Gulshan", Title((await Search("q=gulshan"))[0]));
        var file = Path.Combine(Path.GetTempPath(), $"places-{Guid.NewGuid():N}.geojsonseq");
        await File.WriteAllLinesAsync(file, [
            """{"type":"Feature","id":"n1","properties":{"place":"suburb","name":"Mohammadpur"},"geometry":{"type":"Point","coordinates":[90.358,23.765]}}""",
            """{"type":"Feature","id":"n1","properties":{"place":"suburb","name":"Repeated"},"geometry":{"type":"Point","coordinates":[90.358,23.765]}}""",
        ]);
        var env = Hosts.Environment(url);
        var output = new StringWriter();
        Assert.Equal(0, await ImportPlacesCommand.Run(Hosts.Paths, env, [file], output));
        Assert.Contains("migrate import-places: 1 places", output.ToString(), StringComparison.Ordinal);
        Assert.Equal("Gulshan", Title((await Search("q=gulshan"))[0]));
        Assert.Equal("Mohammadpur", Title((await Search("q=mohammadpur"))[0]));
        Assert.Equal(2, await ImportPlacesCommand.Run(Hosts.Paths, env, [], output));
        Assert.Equal(2, await ImportPlacesCommand.Run(Hosts.Paths, env, [file + ".missing"], output));
        var seeded = new StringWriter();
        Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, env, seeded));
        Assert.Contains("migrate seed: 0 places", seeded.ToString(), StringComparison.Ordinal);
        File.Delete(file);
    }

    [Fact]
    public async Task A_redis_failure_only_costs_a_database_read()
    {
        var options = StackExchange.Redis.ConfigurationOptions.Parse("127.0.0.1:1,abortConnect=false,connectTimeout=100,syncTimeout=200,asyncTimeout=200,connectRetry=0");
        using var broken = await StackExchange.Redis.ConnectionMultiplexer.ConnectAsync(options);
        var cache = new PlaceCache(new JsonCache(broken), api.Services.GetRequiredService<RedisKeys>(), NullLogger<PlaceCache>.Instance);
        var answer = await cache.GetOrAdd(["test"], () => Task.FromResult(new PlaceListView([])));
        Assert.Empty(answer.Items);
    }
}
