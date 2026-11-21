using System.Diagnostics;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Json;

namespace PAO.E2ETests.Support;

/// <summary>A new customer and the ID of their default address, for bookings.</summary>
public sealed record Customer(Session Session, string Address);

/// <summary>App users: sign-in by one-time code, customers with an address, uploads, phones.</summary>
public static partial class Actors
{
    private static readonly HttpClient Storage = new() { Timeout = TimeSpan.FromSeconds(30) };

    /// <summary>The newest one-time code texted to `phone`, read from the SMS capture.</summary>
    public static async Task<string> LastCode(string phone)
    {
        var r = await Get($"/__test/sms?phone={Uri.EscapeDataString(phone)}");
        if (r.Status != 200)
        {
            throw new InvalidOperationException($"no sms to {phone}: {r.Status}");
        }
        var match = SixDigits().Match(Str(r.Json()["message"]));
        return match.Success ? match.Value : string.Empty;
    }

    private static uint Fnv32a(string text)
    {
        var hash = 0x811c9dc5u;
        foreach (var b in Encoding.UTF8.GetBytes(text))
        {
            hash = unchecked((hash ^ b) * 0x01000193u);
        }
        return hash;
    }

    /// <summary>The address `phone`'s device connects from, stable per phone.</summary>
    public static Session DeviceOf(string phone)
    {
        var n = Fnv32a(phone);
        return new Session(Ip: $"198.18.{(n >> 8) & 0xff}.{n & 0xff}");
    }

    /// <summary>Asks for a login code from `phone`'s device.</summary>
    public static Task<Reply> RequestCode(string phone) =>
        Send("POST", "/v1/auth/otp/request", new { phone, purpose = "login" }, DeviceOf(phone));

    /// <summary>Requests and enters a one-time code; `app` is "customer" or "partner".</summary>
    public static async Task<Session> SignIn(string phone, string app)
    {
        var r = await RequestCode(phone);
        if (r.Status != 202)
        {
            throw new InvalidOperationException($"code for {phone}: {r.Status} {r.Body}");
        }
        var device = DeviceOf(phone);
        var code = await LastCode(phone);
        var tokens = (await Send("POST", "/v1/auth/otp/verify", new { phone, code, app }, device)).Expect(200);
        return new Session(Str(Obj(tokens["account"])["id"]), Str(tokens["accessToken"]), device.Ip);
    }

    /// <summary>Signs a new customer up with a profile and a default address in Banani.</summary>
    public static async Task<Customer> CustomerAt(string phone)
    {
        var c = await SignIn(phone, "customer");
        (await Send("PUT", "/v1/customer/profile", new { name = "Nusrat Jahan", language = "en" }, c)).Expect(200);
        var home = new
        {
            label = "home",
            line1 = "House 12, Road 5, Banani",
            location = new { lat = 23.794, lng = 90.407 },
            isDefault = true,
        };
        var address = (await Send("POST", "/v1/customer/addresses", home, c)).Expect(201);
        return new Customer(c, Str(address["id"]));
    }

    /// <summary>`CustomerAt` without the address.</summary>
    public static async Task<Session> NewCustomer(string phone) => (await CustomerAt(phone)).Session;

    /// <summary>
    /// Stores a small confirmed image through the signed URL, as an app would; `role` is
    /// "customer" or "provider". Returns the media ID.
    /// </summary>
    public static async Task<string> Upload(Session s, string role, string purpose)
    {
        var body = Encoding.UTF8.GetBytes("e2e-image");
        var ticket = (await Send("POST", $"/v1/{role}/uploads", new { purpose, contentType = "image/jpeg", sizeBytes = body.Length }, s)).Expect(201);
        using var put = new HttpRequestMessage(HttpMethod.Put, Str(ticket["uploadUrl"])) { Content = new ByteArrayContent(body) };
        foreach (var (key, value) in Obj(ticket["headers"]))
        {
            if (!put.Headers.TryAddWithoutValidation(key, Str(value)))
            {
                put.Content.Headers.TryAddWithoutValidation(key, Str(value));
            }
        }
        using var res = await Storage.SendAsync(put);
        if ((int)res.StatusCode != 200)
        {
            throw new InvalidOperationException($"put {purpose}: {(int)res.StatusCode} {await res.Content.ReadAsStringAsync()}");
        }
        var id = Str(ticket["mediaId"]);
        (await Send("POST", $"/v1/{role}/uploads/{id}/confirm", null, s)).Expect(200);
        return id;
    }

    /// <summary>Gives each test its own Bangladeshi mobile number.</summary>
    public static string PhoneFor(string prefix, int n)
    {
        var micros = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000 + (Stopwatch.GetTimestamp() / (Stopwatch.Frequency / 1_000_000) % 1000);
        var tail = (micros + n) % 100_000_000;
        return prefix + tail.ToString("D8", CultureInfo.InvariantCulture);
    }

    [GeneratedRegex("[0-9]{6}")]
    private static partial Regex SixDigits();
}
