using System.Net;
using System.Text.RegularExpressions;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

/// <summary>The ids one account owns in the sweep.</summary>
public sealed record OwnedIds(Guid Address, Guid Booking, Guid Completed, Guid CustomerNote, Guid ProviderNote, Guid CustomerUpload, Guid ProviderUpload);

/// <summary>
/// Insecure direct object references (ASVS V4.2.1): every customer and provider route of the
/// contract with an owned path id is called by another account of the same role, which must
/// learn nothing: 404 or 403, never the owner's data or a state error that confirms the id.
/// </summary>
public sealed partial class CrossAccountTests : IAsyncLifetime
{
    private static readonly Guid Proposal = Guid.Parse("0190f3a0-0000-7000-8000-000000000001");
    private static readonly object Report = new { reason = "late", description = "Arrived two hours late." };
    private static readonly object Address = new { label = "home", line1 = "House 1", area = "Gulshan", location = new { lat = 23.79, lng = 90.41 } };

    // Path ids that name public records (the catalog, provider profiles), not owned ones.
    private static readonly string[] PublicIds = ["{serviceId}", "{providerId}"];

    // Reviews answer one conflict for any booking the caller may not review (unknown,
    // unfinished or someone else's), so the answer confirms nothing either.
    private static readonly HashSet<string> UniformConflict =
        ["POST /v1/customer/bookings/{bookingId}/review", "POST /v1/provider/jobs/{bookingId}/review"];

    private static readonly Dictionary<string, (Func<OwnedIds, string> Path, object? Body)> Cases = new(StringComparer.Ordinal)
    {
        ["PUT /v1/customer/addresses/{addressId}"] = (o => $"/v1/customer/addresses/{o.Address}", Address),
        ["DELETE /v1/customer/addresses/{addressId}"] = (o => $"/v1/customer/addresses/{o.Address}", null),
        ["POST /v1/customer/addresses/{addressId}/default"] = (o => $"/v1/customer/addresses/{o.Address}/default", null),
        ["GET /v1/customer/bookings/{bookingId}"] = (o => $"/v1/customer/bookings/{o.Booking}", null),
        ["GET /v1/customer/bookings/{bookingId}/start-code"] = (o => $"/v1/customer/bookings/{o.Booking}/start-code", null),
        ["POST /v1/customer/bookings/{bookingId}/cancel"] = (o => $"/v1/customer/bookings/{o.Booking}/cancel", new { reason = "other" }),
        ["POST /v1/customer/bookings/{bookingId}/extras/decision"] = (o => $"/v1/customer/bookings/{o.Booking}/extras/decision", new { proposalId = Proposal, approve = true }),
        ["GET /v1/customer/bookings/{bookingId}/receipt"] = (o => $"/v1/customer/bookings/{o.Booking}/receipt", null),
        ["POST /v1/customer/bookings/{bookingId}/review"] = (o => $"/v1/customer/bookings/{o.Completed}/review", new { stars = 5 }),
        ["POST /v1/customer/bookings/{bookingId}/reports"] = (o => $"/v1/customer/bookings/{o.Booking}/reports", Report),
        ["POST /v1/customer/notifications/{notificationId}/read"] = (o => $"/v1/customer/notifications/{o.CustomerNote}/read", null),
        ["POST /v1/customer/uploads/{mediaId}/confirm"] = (o => $"/v1/customer/uploads/{o.CustomerUpload}/confirm", null),
        ["GET /v1/provider/jobs/{bookingId}"] = (o => $"/v1/provider/jobs/{o.Booking}", null),
        ["POST /v1/provider/jobs/{bookingId}/accept"] = Job("accept"),
        ["POST /v1/provider/jobs/{bookingId}/reject"] = Job("reject", new { reason = "busy" }),
        ["POST /v1/provider/jobs/{bookingId}/on-the-way"] = Job("on-the-way"),
        ["POST /v1/provider/jobs/{bookingId}/arrived"] = Job("arrived"),
        ["POST /v1/provider/jobs/{bookingId}/start"] = Job("start", new { code = "1234" }),
        ["POST /v1/provider/jobs/{bookingId}/extras"] = Job("extras", new { items = new[] { new { subServiceId = Fan, quantity = 1 } } }),
        ["POST /v1/provider/jobs/{bookingId}/complete"] = Job("complete", new { cashReceived = true }),
        ["POST /v1/provider/jobs/{bookingId}/cancel"] = Job("cancel", new { reason = "emergency" }),
        ["POST /v1/provider/jobs/{bookingId}/review"] = (o => $"/v1/provider/jobs/{o.Completed}/review", new { stars = 4 }),
        ["POST /v1/provider/jobs/{bookingId}/reports"] = Job("reports", Report),
        ["GET /v1/provider/jobs/{bookingId}/receipt"] = (o => $"/v1/provider/jobs/{o.Booking}/receipt", null),
        ["POST /v1/provider/notifications/{notificationId}/read"] = (o => $"/v1/provider/notifications/{o.ProviderNote}/read", null),
        ["POST /v1/provider/uploads/{mediaId}/confirm"] = (o => $"/v1/provider/uploads/{o.ProviderUpload}/confirm", null),
    };

    private PeopleApi api = null!;
    private string url = string.Empty;

    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(url = await TestDatabases.CreateMigrated());

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private static (Func<OwnedIds, string>, object?) Job(string action, object? body = null) =>
        (o => $"/v1/provider/jobs/{o.Booking}/{action}", body);

    /// <summary>Every customer or provider operation whose path holds an owned id, read from the bundled contract.</summary>
    public static IReadOnlyList<string> OwnedRoutes()
    {
        var routes = new List<string>();
        string? path = null;
        foreach (var line in File.ReadLines(Hosts.Paths.Spec))
        {
            if (PathLine().Match(line) is { Success: true } p)
            {
                path = p.Groups[1].Value;
            }
            else if (MethodLine().Match(line) is { Success: true } m && path is not null
                && OwnedPath().IsMatch(path) && !PublicIds.Any(path.Contains))
            {
                routes.Add($"{m.Groups[1].Value.ToUpperInvariant()} {path}");
            }
        }
        return [.. routes.Order(StringComparer.Ordinal)];
    }

    [Fact]
    public void Has_a_case_for_every_owned_id_route_in_the_contract() =>
        Assert.Equal(OwnedRoutes(), Cases.Keys.Order(StringComparer.Ordinal));

    [Fact]
    public async Task Another_account_of_the_same_role_gets_nothing()
    {
        var w = await Create(api);
        var completed = await w.Completed("idor-done");
        var booking = await w.Book("idor-booking");
        Assert.Equal(HttpStatusCode.OK, (await w.Job(booking, "accept")).Status);
        await w.Relay();
        var owned = new OwnedIds(
            w.AddressId, booking, completed,
            await FirstNotification(w.Customer.Token, "customer"), await FirstNotification(w.Provider.Token, "provider"),
            await api.Avatar(w.Customer.Token, "customer"), await api.Avatar(w.Provider.Token, "provider"));
        var strangers = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["customer"] = (await NewCustomer(api, "01812345699")).Customer.Token,
            ["provider"] = (await VerifiedProvider(api, "01712345698", Electrician)).Token,
        };
        Assert.Equal(HttpStatusCode.OK, (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{booking}")).Status);
        Assert.Equal(HttpStatusCode.OK, (await w.AsProvider(HttpMethod.Get, $"/v1/provider/jobs/{booking}")).Status);
        var leaks = new List<string>();
        foreach (var (route, (path, body)) in Cases)
        {
            var method = new HttpMethod(route.Split(' ')[0]);
            var r = await w.Send(method, path(owned), strangers[route.Split('/')[2]], body, "idor-" + route.GetHashCode(StringComparison.Ordinal));
            var expected = UniformConflict.Contains(route)
                ? r.Status == HttpStatusCode.Conflict && PeopleApi.Code(r.Body) == "REVIEW_NOT_ALLOWED"
                : r.Status is HttpStatusCode.NotFound or HttpStatusCode.Forbidden;
            if (!expected)
            {
                leaks.Add($"{route}: {(int)r.Status} {r.Body}");
            }
        }
        Assert.Empty(leaks);
        Assert.Equal(HttpStatusCode.OK, (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{booking}")).Status);
    }

    private async Task<Guid> FirstNotification(string token, string side)
    {
        var items = (await api.Call(HttpMethod.Get, $"/v1/{side}/notifications", token)).Body.GetProperty("items");
        Assert.True(items.GetArrayLength() > 0, $"no {side} notification");
        return Guid.Parse(items[0].GetProperty("id").GetString()!);
    }

    [GeneratedRegex(@"^  (/v1/[^:]+):\s*$")]
    private static partial Regex PathLine();

    [GeneratedRegex(@"^    (get|put|post|patch|delete):\s*$")]
    private static partial Regex MethodLine();

    [GeneratedRegex(@"^/v1/(customer|provider)/.*\{")]
    private static partial Regex OwnedPath();
}
