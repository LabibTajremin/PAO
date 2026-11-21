using System.Globalization;
using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;

namespace PAO.LoadTests;

/// <summary>
/// Nearby provider search (P07, 03-testing.md): p95 under 300 ms with the perf seed's
/// online providers, no failed requests and every answer listing providers.
/// </summary>
public static class NearbySearch
{
    // 50 searches a second (P14) spread over 50 customers is one per customer per second,
    // under each customer's rate limit (120 per minute), so the run measures search, not
    // throttling.
    public static readonly ArrivalPlan Plan = new(RatePerSecond: 50, Duration: TimeSpan.FromSeconds(30), MaxInFlight: 25);

    public static readonly ArrivalPlan WarmUp = Plan with { Duration = TimeSpan.FromSeconds(5) };

    public static readonly Thresholds Thresholds = new(P95: TimeSpan.FromMilliseconds(300), MaxFailureRate: 0, MinCheckRate: 1);

    public static async Task<Sample> Send(HttpClient http, PerfFixture fixture, int iteration)
    {
        var token = fixture.Tokens[(int)((iteration * 31L) % fixture.Tokens.Count)];
        using var request = new HttpRequestMessage(HttpMethod.Get, Url(fixture));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        using var response = await http.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();
        var failed = (int)response.StatusCode >= 400;
        return new Sample(TimeSpan.Zero, failed, response.StatusCode == HttpStatusCode.OK && HasProviders(body));
    }

    private static string Url(PerfFixture f) => string.Create(
        CultureInfo.InvariantCulture,
        $"/v1/customer/providers/nearby?serviceId={f.ServiceId}&subServiceId={f.SubServiceId}&quantity=1&lat={f.Lat}&lng={f.Lng}&limit=20");

    private static bool HasProviders(string body)
    {
        try
        {
            using var json = JsonDocument.Parse(body);
            return json.RootElement.TryGetProperty("items", out var items)
                && items.ValueKind == JsonValueKind.Array
                && items.GetArrayLength() > 0;
        }
        catch (JsonException)
        {
            return false;
        }
    }
}
