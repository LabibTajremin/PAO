using System.Net;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.EF;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.IntegrationTests.Areas;

public sealed class CustomerApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private static readonly object Profile = new { name = "Nusrat Jahan", language = "bn" };
    private PeopleApi api = null!;

    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(database.Url);

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private static object Address(string label, bool isDefault) => new
    {
        label,
        line1 = "House 12, Road 5",
        line2 = "Block C",
        area = "Banani",
        location = new { lat = 23.7937, lng = 90.4066 },
        isDefault,
    };

    private async Task<string> Add(string token, object body)
    {
        var r = await api.Call(HttpMethod.Post, "/v1/customer/addresses", token, body);
        Assert.Equal(HttpStatusCode.Created, r.Status);
        return r.Body.GetProperty("id").GetString()!;
    }

    private async Task<(List<string> All, string? Default)> List(string token)
    {
        var items = (await api.Call(HttpMethod.Get, "/v1/customer/addresses", token)).Body.GetProperty("items").EnumerateArray().ToList();
        return ([.. items.Select(i => i.GetProperty("id").GetString()!)],
            items.Where(i => i.GetProperty("isDefault").GetBoolean()).Select(i => i.GetProperty("id").GetString()).FirstOrDefault());
    }

    private T Contract<T>(Func<ICustomerSharedService, Task<T>> call)
    {
        using var scope = api.Services.CreateScope();
        return call(scope.ServiceProvider.GetRequiredService<ICustomerSharedService>()).GetAwaiter().GetResult();
    }

    [Fact]
    public async Task Needs_a_profile_first_saves_it_and_erases_it_with_the_account()
    {
        var (id, token) = await api.SignIn("01712345678", "customer");
        Assert.Equal("PROFILE_NOT_FOUND", PeopleApi.Code((await api.Call(HttpMethod.Get, "/v1/customer/profile", token)).Body));
        var early = await api.Call(HttpMethod.Post, "/v1/customer/addresses", token, Address("home", false));
        Assert.Equal("PROFILE_REQUIRED", PeopleApi.Code(early.Body));
        var saved = await api.Call(HttpMethod.Put, "/v1/customer/profile", token, new { name = " Nusrat ", language = "en" });
        Assert.Equal(HttpStatusCode.OK, saved.Status);
        Assert.Equal(("+8801712345678", "Nusrat"), (saved.Body.GetProperty("phone").GetString(), saved.Body.GetProperty("name").GetString()));
        Assert.False(saved.Body.TryGetProperty("photoUrl", out _));
        Assert.Equal("en", (await api.Call(HttpMethod.Get, "/v1/customer/profile", token)).Body.GetProperty("language").GetString());
        var shortName = await api.Call(HttpMethod.Put, "/v1/customer/profile", token, new { name = "N ", language = "bn" });
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code(shortName.Body));
        await Add(token, Address("home", false));
        Assert.Equal("Nusrat", Contract(c => c.GetCustomer(id, CancellationToken.None)).Name);
        await api.Deliver("identity.AccountDeleted", new { accountId = id });
        Assert.Equal(CustomerErrors.NotFound, Assert.Throws<DomainException>(() => Contract(c => c.GetCustomer(id, CancellationToken.None))).Reason);
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<PaoDbContext>();
        Assert.Equal(0, await db.Database.SqlQuery<int>($"SELECT count(*)::int AS \"Value\" FROM customer.addresses WHERE customer_id = {id}").SingleAsync());
        await Assert.ThrowsAnyAsync<Exception>(() => api.Deliver("identity.AccountDeleted", new { }));
    }

    [Fact]
    public async Task Accepts_only_the_customers_own_confirmed_avatar()
    {
        var (_, token) = await api.SignIn("01712345677", "customer");
        var unknown = new { name = "Nusrat", language = "bn", photoMediaId = Guid.NewGuid() };
        Assert.Equal("UPLOAD_INVALID", PeopleApi.Code((await api.Call(HttpMethod.Put, "/v1/customer/profile", token, unknown)).Body));
        var photo = await api.Avatar(token, "customer");
        var saved = await api.Call(HttpMethod.Put, "/v1/customer/profile", token, new { name = "Nusrat", language = "en", photoMediaId = photo });
        Assert.Equal(HttpStatusCode.OK, saved.Status);
        Assert.StartsWith("http", saved.Body.GetProperty("photoUrl").GetString(), StringComparison.Ordinal);
        Assert.True((await api.Call(HttpMethod.Get, "/v1/customer/profile", token)).Body.TryGetProperty("photoUrl", out _));
        var (_, other) = await api.SignIn("01712345676", "customer");
        var theirs = await api.Avatar(other, "customer");
        var refused = await api.Call(HttpMethod.Put, "/v1/customer/profile", token, new { name = "Nusrat", language = "bn", photoMediaId = theirs });
        Assert.Equal("UPLOAD_INVALID", PeopleApi.Code(refused.Body));
        var ghost = api.Api.Token("customer");
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Put, "/v1/customer/profile", ghost, Profile)).Status);
    }

    [Fact]
    public async Task Switches_defaults_promotes_the_newest_caps_at_ten_and_hides_others()
    {
        var (id, token) = await api.SignIn("01712345675", "customer");
        await api.Call(HttpMethod.Put, "/v1/customer/profile", token, Profile);
        var first = await Add(token, Address("home", false));
        var second = await Add(token, Address("office", true));
        var list = await List(token);
        Assert.Equal((2, second), (list.All.Count, list.Default));
        var path = $"/v1/customer/addresses/{first}";
        var edited = await api.Call(HttpMethod.Put, path, token, new { label = "other", line1 = "House 14, Road 7", location = new { lat = 23.8, lng = 90.4 }, isDefault = true });
        Assert.True(edited.Body.GetProperty("isDefault").GetBoolean());
        Assert.Equal(("House 14, Road 7", ""), (edited.Body.GetProperty("line1").GetString(), edited.Body.GetProperty("line2").GetString()));
        Assert.True((await api.Call(HttpMethod.Post, $"/v1/customer/addresses/{second}/default", token)).Body.GetProperty("isDefault").GetBoolean());
        Assert.False((await api.Call(HttpMethod.Put, path, token, Address("home", false))).Body.GetProperty("isDefault").GetBoolean());
        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Delete, path, token)).Status);
        var third = await Add(token, Address("home", false));
        await api.Call(HttpMethod.Delete, $"/v1/customer/addresses/{second}", token);
        Assert.Equal(third, (await List(token)).Default);
        for (var i = 0; i < 9; i++)
        {
            await Add(token, Address("other", false));
        }
        Assert.Equal("ADDRESS_LIMIT_REACHED", PeopleApi.Code((await api.Call(HttpMethod.Post, "/v1/customer/addresses", token, Address("other", false))).Body));
        var got = Contract(c => c.GetAddress(id, Guid.Parse(third), CancellationToken.None));
        Assert.Equal(("Banani", 90.4066), (got.Area, got.Location.Lng));
        var (_, stranger) = await api.SignIn("01912345679", "customer");
        await api.Call(HttpMethod.Put, "/v1/customer/profile", stranger, Profile);
        var thirdPath = $"/v1/customer/addresses/{third}";
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Put, thirdPath, stranger, Address("home", false))).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Delete, thirdPath, stranger)).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"{thirdPath}/default", stranger)).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Put, thirdPath, stranger, Address("home", true))).Status);
        Assert.Equal(CustomerErrors.AddressNotFound, Assert.Throws<DomainException>(() => Contract(c => c.GetAddress(id, Guid.NewGuid(), CancellationToken.None))).Reason);
    }

    [Fact]
    public async Task Validates_pins_and_checks_the_launch_area()
    {
        var (_, token) = await api.SignIn("01812345670", "customer");
        await api.Call(HttpMethod.Put, "/v1/customer/profile", token, Profile);
        var abroad = new { label = "home", line1 = "House 12", location = new { lat = 51.5, lng = -0.12 } };
        Assert.Equal("OUTSIDE_SERVICE_AREA", PeopleApi.Code((await api.Call(HttpMethod.Post, "/v1/customer/addresses", token, abroad)).Body));
        Assert.Equal("OUTSIDE_SERVICE_AREA", PeopleApi.Code((await api.Call(HttpMethod.Put, $"/v1/customer/addresses/{Guid.NewGuid()}", token, abroad)).Body));
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Put, $"/v1/customer/addresses/{Guid.NewGuid()}", token, Address("home", false))).Status);
        var plain = await api.Call(HttpMethod.Post, "/v1/customer/addresses", token, new { label = "home", line1 = "Road 5", location = new { lat = 23.8, lng = 90.4 } });
        Assert.Equal((HttpStatusCode.Created, ""), (plain.Status, plain.Body.GetProperty("line2").GetString()));
        Assert.True((await api.Call(HttpMethod.Get, "/v1/customer/service-area?lat=23.8&lng=90.4", token)).Body.GetProperty("covered").GetBoolean());
        await api.SetSetting("service_area.geojson", """{"type":"Polygon","coordinates":[[[90.3,23.7],[90.5,23.7],[90.5,23.9],[90.3,23.9],[90.3,23.7]]]}""");
        Assert.True((await api.Call(HttpMethod.Get, "/v1/customer/service-area?lat=23.8&lng=90.4", token)).Body.GetProperty("covered").GetBoolean());
        Assert.False(Contract(c => c.IsInServiceArea(new GeoPoint { Lat = 22.3, Lng = 91.8 }, CancellationToken.None)));
        await api.SettingsDown(true);
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Get, "/v1/customer/service-area?lat=23.8&lng=90.4", token)).Status);
        await api.SettingsDown(false);
    }

    [Fact]
    public async Task Keeps_the_admin_list_copies_current_from_events()
    {
        var (id, token) = await api.SignIn("01712345670", "customer");
        await api.Call(HttpMethod.Put, "/v1/customer/profile", token, Profile);
        var bus = api.Bus();
        await api.Deliver("identity.AccountStatusChanged", new { accountId = id, from = "active", to = "suspended", roles = new[] { "customer" } }, bus);
        await api.Deliver("identity.AccountStatusChanged", new { accountId = id, from = "suspended", to = "banned", roles = new[] { "provider" } }, bus);
        await api.Deliver("booking.BookingRequested", new { customerId = id }, bus);
        await api.Deliver("booking.BookingRequested", new { }, bus);
        var query = new CustomerQuery { Id = id, Text = " NUSRAT ", Status = "suspended", Limit = 10 };
        var row = Assert.Single(Contract(c => c.SearchCustomers(query, CancellationToken.None)));
        Assert.Equal(("suspended", 1, "+8801712345670"), (row.Status, row.Bookings, row.Phone));
        Assert.Empty(Contract(c => c.SearchCustomers(new CustomerQuery { Text = "Nus%", Status = string.Empty, Limit = 10 }, CancellationToken.None)));
        var after = new CustomerQuery { Text = string.Empty, Status = string.Empty, AfterAt = DateTimeOffset.UtcNow.AddDays(1), AfterId = Guid.NewGuid(), Limit = 50 };
        Assert.Contains(Contract(c => c.SearchCustomers(after, CancellationToken.None)), r => r.Id == id);
        await Assert.ThrowsAnyAsync<Exception>(() => api.Deliver("identity.AccountStatusChanged", new { to = "x" }, bus));
    }

    [Fact]
    public async Task Fails_cleanly_when_the_address_table_is_gone()
    {
        var (_, token) = await api.SignIn("01712345671", "customer");
        await api.Call(HttpMethod.Put, "/v1/customer/profile", token, Profile);
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<PaoDbContext>();
        await db.Database.ExecuteSqlRawAsync("ALTER TABLE customer.addresses RENAME TO gone");
        try
        {
            Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Post, "/v1/customer/addresses", token, Address("home", false))).Status);
            Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Get, "/v1/customer/addresses", token)).Status);
        }
        finally
        {
            await db.Database.ExecuteSqlRawAsync("ALTER TABLE customer.gone RENAME TO addresses");
        }
    }
}
