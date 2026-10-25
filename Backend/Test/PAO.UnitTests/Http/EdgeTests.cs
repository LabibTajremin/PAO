using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using PAO.Infrastructure.Http;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Http.OpenApi;
using PAO.Lib.Errors;

namespace PAO.UnitTests.Http;

internal static class Contexts
{
    public static DefaultHttpContext New(string method = "GET", string path = "/", string? body = null, string? contentType = null)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Path = path;
        context.Request.ContentType = contentType;
        context.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(body ?? string.Empty));
        context.Response.Body = new MemoryStream();
        return context;
    }

    public static string Body(HttpContext context)
    {
        context.Response.Body.Position = 0;
        return new StreamReader(context.Response.Body).ReadToEnd();
    }

    public static readonly RequestDelegate Done = _ => Task.CompletedTask;
}

public sealed class ErrorResponseTests
{
    [Fact]
    public async Task Writes_the_envelope_with_details_and_retry_after()
    {
        var context = Contexts.New();
        await ErrorResponses.Write(context, ApiErrors.RateLimited("RATE_LIMITED", TimeSpan.FromMilliseconds(2500)).WithDetails(new Dictionary<string, object?> { ["limit"] = 60 }), NullLogger.Instance);
        Assert.Equal(429, context.Response.StatusCode);
        Assert.Equal("2", context.Response.Headers.RetryAfter);
        Assert.Equal("{\"error\":{\"code\":\"RATE_LIMITED\",\"message\":\"Too many requests. Try again later.\",\"details\":{\"limit\":60}}}\n", Contexts.Body(context));
    }

    [Fact]
    public async Task Hides_unexpected_errors_and_replays_stored_answers()
    {
        var context = Contexts.New();
        await ErrorResponses.Write(context, new InvalidOperationException("secret"), NullLogger.Instance);
        Assert.Equal(500, context.Response.StatusCode);
        Assert.DoesNotContain("secret", Contexts.Body(context), StringComparison.Ordinal);
        var replay = Contexts.New();
        await ErrorResponses.Write(replay, new StoredResponseException(201, "{}"u8.ToArray()), NullLogger.Instance);
        Assert.Equal(201, replay.Response.StatusCode);
        Assert.Equal("true", replay.Response.Headers["Idempotent-Replayed"]);
        Assert.Equal("{}", Contexts.Body(replay));
    }

    [Theory]
    [InlineData(400, 422, "VALIDATION_FAILED")]
    [InlineData(413, 422, "VALIDATION_FAILED")]
    [InlineData(401, 401, "UNAUTHENTICATED")]
    [InlineData(403, 403, "FORBIDDEN")]
    [InlineData(404, 404, "NOT_FOUND")]
    [InlineData(422, 422, "VALIDATION_FAILED")]
    [InlineData(408, 500, "INTERNAL")]
    public void Maps_framework_errors(int status, int expected, string code)
    {
        var error = ErrorResponses.ToApiError(new BadHttpRequestException("bad", status));
        Assert.Equal(expected, error.Status);
        Assert.Equal(code, error.Code);
        Assert.IsType<BadHttpRequestException>(error.InnerException);
    }

    [Fact]
    public async Task Only_logs_when_the_response_already_started()
    {
        var context = Contexts.New();
        var started = new StartedResponse();
        context.Features.Set<Microsoft.AspNetCore.Http.Features.IHttpResponseFeature>(started);
        await ErrorResponses.Write(context, ApiErrors.NotFound, NullLogger.Instance);
        Assert.Equal(200, started.StatusCode);
    }

    private sealed class StartedResponse : Microsoft.AspNetCore.Http.Features.HttpResponseFeature
    {
        public override bool HasStarted => true;
    }

    private sealed class Map : IErrorMap
    {
        public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
        {
            ["booking.not_found"] = new(404, "BOOKING_NOT_FOUND", "Booking not found."),
        };
    }

    [Fact]
    public void Error_maps_translate_domain_reasons_found_in_causes()
    {
        var map = new ErrorMapAttribute(typeof(Map));
        var mapped = Assert.IsType<ApiError>(map.Apply(new InvalidOperationException("x", new DomainException("booking.not_found"))));
        Assert.Equal("BOOKING_NOT_FOUND", mapped.Code);
        var other = new DomainException("booking.other");
        Assert.Same(other, map.Apply(other));
        Assert.Equal("INTERNAL", ApiErrors.Internal.Wrap(other).WithDetails(new Dictionary<string, object?>()).Code);
    }
}

public sealed class EdgeMiddlewareTests
{
    [Fact]
    public async Task Trusts_forwarded_for_only_from_private_peers()
    {
        var context = Contexts.New();
        context.Connection.RemoteIpAddress = IPAddress.Parse("::ffff:10.0.0.5");
        context.Request.Headers["X-Forwarded-For"] = "1.1.1.1, 203.0.113.9";
        await EdgeMiddleware.ClientAddress(context, Contexts.Done);
        Assert.Equal("203.0.113.9", context.Edge().ClientIp);
        Assert.Equal("8.8.8.8", ClientIp.Resolve("8.8.8.8", ["1.1.1.1"]));
        Assert.Equal("10.0.0.5", ClientIp.Resolve("10.0.0.5", []));
        Assert.Equal("10.0.0.5", ClientIp.Resolve("10.0.0.5", ["garbage"]));
        Assert.Equal(string.Empty, ClientIp.Normalize(null));
    }

    [Theory]
    [InlineData("10.1.2.3", true)]
    [InlineData("172.31.0.1", true)]
    [InlineData("172.32.0.1", false)]
    [InlineData("192.168.1.1", true)]
    [InlineData("127.0.0.1", true)]
    [InlineData("::1", true)]
    [InlineData("fd00::1", true)]
    [InlineData("2001:db8::1", false)]
    [InlineData("8.8.8.8", false)]
    [InlineData("nope", false)]
    public void Knows_private_networks(string ip, bool isPrivate)
    {
        Assert.Equal(isPrivate, ClientIp.IsPrivate(ip));
    }

    [Fact]
    public async Task Keeps_a_well_formed_request_id_or_issues_one()
    {
        var context = Contexts.New();
        context.Request.Headers["X-Request-ID"] = "abc-12345";
        await EdgeMiddleware.RequestId(context, Contexts.Done);
        Assert.Equal("abc-12345", context.Response.Headers["X-Request-ID"]);
        var bad = Contexts.New();
        bad.Request.Headers["X-Request-ID"] = "x";
        await EdgeMiddleware.RequestId(bad, Contexts.Done);
        Assert.True(Guid.TryParse(bad.Response.Headers["X-Request-ID"], out _));
    }

    [Fact]
    public async Task Sets_security_headers_and_cors_for_the_admin_origin_only()
    {
        var context = Contexts.New("OPTIONS");
        context.Request.Headers.Origin = "http://admin";
        context.Request.Headers["Access-Control-Request-Method"] = "POST";
        await EdgeMiddleware.SecurityHeaders(context, Contexts.Done);
        var called = false;
        await EdgeMiddleware.Cors("http://admin")(context, _ => { called = true; return Task.CompletedTask; });
        Assert.False(called);
        Assert.Equal(204, context.Response.StatusCode);
        Assert.Equal("http://admin", context.Response.Headers.AccessControlAllowOrigin);
        Assert.Equal("DENY", context.Response.Headers.XFrameOptions);
        Assert.Equal("nosniff", context.Response.Headers.XContentTypeOptions);
        Assert.Equal("default-src 'none'; frame-ancestors 'none'", context.Response.Headers.ContentSecurityPolicy);
        Assert.Equal("max-age=31536000; includeSubDomains", context.Response.Headers.StrictTransportSecurity);
        var other = Contexts.New();
        other.Request.Headers.Origin = "http://evil";
        await EdgeMiddleware.Cors("http://admin")(other, _ => { called = true; return Task.CompletedTask; });
        Assert.True(called);
        Assert.False(other.Response.Headers.ContainsKey("Access-Control-Allow-Origin"));
    }

    [Theory]
    [InlineData("""{"a":1}""", "application/json", null, true)]
    [InlineData("", "application/json", null, false)]
    [InlineData("{oops", "application/json; charset=utf-8", "request body is not valid JSON", false)]
    [InlineData("{oops", "text/plain", null, false)]
    [InlineData("0123456789-too-long", "application/json", "request body too large", false)]
    public async Task Reads_the_body_once_and_records_problems(string body, string contentType, string? error, bool parsed)
    {
        var context = Contexts.New("POST", "/", body, contentType);
        await EdgeMiddleware.ReadBody(16)(context, Contexts.Done);
        Assert.Equal(error, context.Edge().BodyError);
        Assert.Equal(parsed, context.Edge().Body is not null);
        Assert.Equal(error == "request body too large" ? string.Empty : body, await new StreamReader(context.Request.Body).ReadToEndAsync());
    }

    [Fact]
    public async Task Records_unreadable_bodies()
    {
        var context = Contexts.New("POST");
        context.Request.Body = new BrokenStream();
        await EdgeMiddleware.ReadBody(16)(context, Contexts.Done);
        Assert.Equal("request body could not be read", context.Edge().BodyError);
    }

    private sealed class BrokenStream : MemoryStream
    {
        public override ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default) => throw new IOException("reset");
    }

    [Fact]
    public async Task Matches_operations_and_answers_404_and_405_before_controllers()
    {
        var routes = new SpecRoutes(OpenApiTests.Document());
        var nextCalls = 0;
        var middleware = new SpecMatchMiddleware(_ => { nextCalls++; return Task.CompletedTask; }, routes, [new NonSpecRoute("GET", "/healthz")], NullLogger<SpecMatchMiddleware>.Instance);
        var health = Contexts.New("GET", "/healthz");
        await middleware.InvokeAsync(health);
        Assert.Equal("/healthz", health.Edge().RouteTemplate);
        var postHealth = Contexts.New("POST", "/healthz");
        await middleware.InvokeAsync(postHealth);
        Assert.Equal(405, postHealth.Response.StatusCode);
        var op = Contexts.New("GET", "/v1/things/latest");
        await middleware.InvokeAsync(op);
        Assert.Equal("latestThing", op.Edge().Operation!.Operation.Id);
        var missing = Contexts.New("GET", "/v9");
        await middleware.InvokeAsync(missing);
        Assert.Equal(404, missing.Response.StatusCode);
        var wrong = Contexts.New("PUT", "/v1/things");
        await middleware.InvokeAsync(wrong);
        Assert.Equal(405, wrong.Response.StatusCode);
        Assert.Contains("\"NOT_FOUND\"", Contexts.Body(wrong), StringComparison.Ordinal);
        Assert.Equal(2, nextCalls);
    }

    [Fact]
    public async Task The_outer_guard_answers_anything_that_escapes()
    {
        var context = Contexts.New();
        await new ErrorEnvelopeMiddleware(_ => throw ApiErrors.Forbidden, NullLogger<ErrorEnvelopeMiddleware>.Instance).InvokeAsync(context);
        Assert.Equal(403, context.Response.StatusCode);
        Assert.Equal("FORBIDDEN", JsonDocument.Parse(Contexts.Body(context)).RootElement.GetProperty("error").GetProperty("code").GetString());
    }
}

public sealed class CursorTests
{
    [Fact]
    public void Round_trips_and_reads_existing_cursors()
    {
        var cursor = new Cursor("2026-10-17T10:00:00.123456Z", "0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c");
        Assert.Equal(cursor, Cursor.Decode(cursor.Encode()));
        Assert.Null(Cursor.Decode(null));
        Assert.Null(Cursor.Decode(string.Empty));
    }

    [Theory]
    [InlineData("!!")]
    [InlineData("bm90IGpzb24")]
    [InlineData("W10")]
    [InlineData("eyJ0IjoieCIsImkiOiIwMTkwYTViMi03YzFkLTdlM2YtOGE5Yi0wYzFkMmUzZjRhNWMifQ")]
    [InlineData("eyJ0IjoiMjAyNi0xMC0xN1QxMDowMDowMFoiLCJpIjoiMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwIn0")]
    [InlineData("eyJ0IjoiMjAyNi0xMC0xN1QxMDowMDowMFoifQ")]
    [InlineData("A")]
    public void Malformed_cursors_are_a_422(string text)
    {
        var error = Assert.Throws<ApiError>(() => Cursor.Decode(text));
        Assert.Equal("cursor", error.Details!["field"]);
    }

    [Theory]
    [InlineData(null, 20)]
    [InlineData(0, 20)]
    [InlineData(5, 5)]
    [InlineData(500, 100)]
    public void Clamps_page_sizes(int? limit, int size)
    {
        Assert.Equal(size, Cursor.PageSize(limit));
    }
}
