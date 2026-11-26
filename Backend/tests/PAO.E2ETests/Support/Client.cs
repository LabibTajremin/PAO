using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace PAO.E2ETests.Support;

/// <summary>
/// A caller; without a token it is anonymous. `Ip` is the address the caller appears to
/// connect from: the API trusts X-Forwarded-For from the private network the runner
/// reaches it through, so per-IP limits treat actors as the separate devices they stand for.
/// </summary>
public sealed record Session(string? Id = null, string? Token = null, string? Ip = null)
{
    public static readonly Session Anonymous = new();
}

/// <summary>A decoded API reply.</summary>
public sealed class Reply(int status, string body, string what)
{
    public int Status { get; } = status;

    public string Body { get; } = body;

    /// <summary>Fails unless the status is `want`; returns the body, or {} when it is empty.</summary>
    public JsonObject Expect(int want)
    {
        if (Status != want)
        {
            throw new InvalidOperationException($"{what}: want {want}, got {Status} {Body}");
        }
        return Body.Length == 0 ? [] : Json();
    }

    public JsonObject Json() => Support.Json.Obj(JsonNode.Parse(Body));

    /// <summary>The error code of a failed call, or "" when there is none.</summary>
    public string Code()
    {
        if (Body.Length == 0)
        {
            return string.Empty;
        }
        var code = JsonNode.Parse(Body) is JsonObject o && o["error"] is JsonObject e ? e["code"] : null;
        return code is JsonValue v && v.TryGetValue<string>(out var s) ? s : string.Empty;
    }
}

/// <summary>Plain HTTP against the stack; no backend types are referenced.</summary>
public static class Client
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(30) };

    /// <summary>Sends a JSON request to base + path.</summary>
    public static async Task<Reply> Call(string baseUrl, string method, string path, object? body = null, Session? actor = null, IDictionary<string, string>? headers = null)
    {
        using var request = new HttpRequestMessage(new HttpMethod(method), baseUrl + path);
        var who = actor ?? Session.Anonymous;
        if (who.Token is not null)
        {
            request.Headers.Add("Authorization", "Bearer " + who.Token);
        }
        if (who.Ip is not null)
        {
            request.Headers.Add("X-Forwarded-For", who.Ip);
        }
        foreach (var (key, value) in headers ?? new Dictionary<string, string>())
        {
            request.Headers.Add(key, value);
        }
        if (body is not null)
        {
            request.Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");
        }
        using var response = await Http.SendAsync(request);
        return new Reply((int)response.StatusCode, await response.Content.ReadAsStringAsync(), $"{method} {path}");
    }

    /// <summary>Calls the API.</summary>
    public static Task<Reply> Send(string method, string path, object? body, Session? actor = null) =>
        Call(Stack.Current.Api, method, path, body, actor);

    /// <summary>GETs from the API.</summary>
    public static Task<Reply> Get(string path, Session? actor = null) => Send("GET", path, null, actor);

    /// <summary>
    /// Retries `check` until it passes or `within` runs out; the worker relays events
    /// asynchronously, so the effects of an action land shortly after it.
    /// </summary>
    public static async Task Eventually(TimeSpan within, string what, Func<Task<bool>> check)
    {
        var clock = Stopwatch.StartNew();
        while (!await check())
        {
            if (clock.Elapsed > within)
            {
                throw new TimeoutException($"timed out waiting for {what}");
            }
            await Task.Delay(200);
        }
    }

    public static TimeSpan Seconds(int n) => TimeSpan.FromSeconds(n);
}
