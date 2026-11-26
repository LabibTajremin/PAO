using System.Diagnostics;
using System.Text.Json.Nodes;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Json;

namespace PAO.E2ETests.Support;

/// <summary>An approved, online provider whose phone registered a push token.</summary>
public sealed record Partner(Session Session, string Id, string Phone, string PushToken);

/// <summary>One item of a booking request.</summary>
public sealed record Line(Sub Sub, int Quantity);

/// <summary>Who books what, where.</summary>
public sealed record Order(Session Customer, string Address, string ProviderId, string ServiceId);

/// <summary>Booking helpers: online providers, requests, provider actions, pushes, settings.</summary>
public static class Bookings
{
    /// <summary>
    /// Enrols a provider for `serviceId`, has every item approved, registers a device for
    /// pushes and brings them online; they go offline when the test ends so later runs do
    /// not page through them in nearby search.
    /// </summary>
    public static async Task<Partner> OnlineProvider(int n, string serviceId)
    {
        var phone = Actors.PhoneFor("018", n);
        var session = await Providers.EnrolledProvider(phone, serviceId, DateTimeOffset.UtcNow.AddMonths(-1));
        await Providers.Approve(session, Providers.Items);
        var pushToken = $"e2e-push-{phone}-{Stopwatch.GetTimestamp()}";
        (await Send("PUT", "/v1/provider/device-token", new { token = pushToken, platform = "android" }, session)).Expect(204);
        await Providers.GoOnline(session);
        Journey.OnCleanup(() => Send("POST", "/v1/provider/presence/offline", null, session));
        return new Partner(session, session.Id!, phone, pushToken);
    }

    /// <summary>The request body for booking lines.</summary>
    public static object[] Lines(params Line[] ls) => ls.Select(l => (object)new { subServiceId = l.Sub.Id, quantity = l.Quantity }).ToArray();

    /// <summary>
    /// Has the customer request an ASAP booking with the provider at the address, with a
    /// fresh idempotency key, and returns the created booking.
    /// </summary>
    public static async Task<JsonObject> BookAsap(Order order, params Line[] ls)
    {
        var c = order.Customer;
        var body = new { providerId = order.ProviderId, serviceId = order.ServiceId, timing = "asap", addressId = order.Address, items = Lines(ls), note = "Second floor" };
        var key = $"e2e-{c.Id}-{Stopwatch.GetTimestamp()}";
        var r = await Call(Stack.Current.Api, "POST", "/v1/customer/bookings", body, c, new Dictionary<string, string> { ["Idempotency-Key"] = key });
        var b = r.Expect(201);
        if (Str(b["status"]) != "requested")
        {
            throw new InvalidOperationException($"new booking: {r.Body}");
        }
        return b;
    }

    /// <summary>Sends a provider action ("accept", "on-the-way", "start", ...) on a booking.</summary>
    public static Task<Reply> Job(Partner p, string bookingId, string action, object? body = null) =>
        Send("POST", $"/v1/provider/jobs/{bookingId}/{action}", body, p.Session);

    /// <summary>`Job` that fails unless the action succeeds, returning the booking.</summary>
    public static async Task<JsonObject> MustJob(Partner p, string bookingId, string action, object? body = null) =>
        (await Job(p, bookingId, action, body)).Expect(200);

    /// <summary>The code the customer reads out to the provider on arrival.</summary>
    public static async Task<string> StartCode(Session c, string bookingId) =>
        Str((await Get($"/v1/customer/bookings/{bookingId}/start-code", c)).Expect(200)["code"]);

    /// <summary>Takes an accepted booking to in_progress with the customer's start code.</summary>
    public static async Task StartJob(Session c, Partner p, string bookingId)
    {
        var code = await StartCode(c, bookingId);
        await MustJob(p, bookingId, "on-the-way");
        await MustJob(p, bookingId, "arrived");
        var b = await MustJob(p, bookingId, "start", new { code });
        if (Str(b["status"]) != "in_progress")
        {
            throw new InvalidOperationException($"start: {b.ToJsonString()}");
        }
    }

    /// <summary>The booking status the customer sees.</summary>
    public static async Task<string> CustomerStatus(Session c, string bookingId) =>
        Str((await Get($"/v1/customer/bookings/{bookingId}", c)).Expect(200)["status"]);

    /// <summary>Whether the worker sent a push of the template about the booking to the token.</summary>
    public static async Task<bool> Pushed(string token, string template, string bookingId)
    {
        var r = await Call(Stack.Current.Worker, "GET", $"/__test/pushes?token={Uri.EscapeDataString(token)}");
        return List(r.Expect(200)["pushes"]).Any(push =>
            push["data"] is JsonObject data && data["type"]?.ToString() == template && data["bookingId"]?.ToString() == bookingId);
    }

    /// <summary>
    /// Changes an admin setting as the super admin and restores the old value when the test
    /// ends, so a failing test cannot leave the stack reconfigured.
    /// </summary>
    public static async Task SetSetting(string key, string value)
    {
        var root = await Admins.Admin("super@pao.bd");
        var settings = List((await Get("/v1/admin/settings", root)).Expect(200)["items"]);
        var old = settings.FirstOrDefault(s => s["key"]?.ToString() == key)?["value"]?.ToString();
        if (string.IsNullOrEmpty(old))
        {
            throw new InvalidOperationException($"no setting {key}");
        }
        async Task Put(string v) => (await Send("PUT", $"/v1/admin/settings/{key}", new { value = v }, root)).Expect(200);
        await Put(value);
        Journey.OnCleanup(() => Put(old));
    }
}
