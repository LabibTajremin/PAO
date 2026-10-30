using System.Net;
using System.Reflection;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Http.Filters;
using PAO.Infrastructure.Http.OpenApi;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Outbox;
using PAO.Infrastructure.Push;
using PAO.Infrastructure.Sms;
using PAO.Infrastructure.Testing;
using PAO.UnitTests.Infrastructure;

namespace PAO.UnitTests.Http;

public sealed class TestHookTests
{
    private sealed class Expiry : IDocumentExpiry
    {
        public DateTimeOffset? At { get; private set; }

        public Task ExpireDocumentsAt(DateTimeOffset at, CancellationToken cancellationToken)
        {
            At = at;
            return Task.CompletedTask;
        }
    }

    private static async Task<(bool Handled, HttpContext Context)> Call(IServiceProvider services, string method, string url)
    {
        var context = Contexts.New(method, url.Split('?')[0]);
        context.Request.QueryString = new QueryString(url.Contains('?', StringComparison.Ordinal) ? "?" + url.Split('?')[1] : string.Empty);
        context.RequestServices = services;
        return (await TestHooks.Handle(context), context);
    }

    [Fact]
    public async Task Read_captured_codes_and_pushes_and_run_the_expiry_sweep()
    {
        var sms = new CapturedSmsSender();
        await sms.Send("+8801712345678", "code 1", CancellationToken.None);
        var pushes = new CapturePushSender(NullLogger<CapturePushSender>.Instance);
        await pushes.Push("dev", new PushMessage("t", "b", new Dictionary<string, string>()), CancellationToken.None);
        var expiry = new Expiry();
        var services = new ServiceCollection()
            .AddSingleton<ISmsCapture>(sms).AddSingleton<IPushCapture>(pushes).AddSingleton<IDocumentExpiry>(expiry).BuildServiceProvider();
        var (_, code) = await Call(services, "GET", "/__test/sms?phone=01712345678");
        Assert.Equal("code 1", JsonDocument.Parse(Contexts.Body(code)).RootElement.GetProperty("message").GetString());
        Assert.Equal(400, (await Call(services, "GET", "/__test/sms?phone=x")).Context.Response.StatusCode);
        Assert.Equal(404, (await Call(services, "GET", "/__test/sms?phone=01812345678")).Context.Response.StatusCode);
        var (_, sent) = await Call(services, "GET", "/__test/pushes?token=dev");
        Assert.Equal(1, JsonDocument.Parse(Contexts.Body(sent)).RootElement.GetProperty("pushes").GetArrayLength());
        Assert.Equal(204, (await Call(services, "POST", "/__test/verification/expire?at=2026-10-17T00:00:00Z")).Context.Response.StatusCode);
        Assert.Equal(DateTimeOffset.Parse("2026-10-17T00:00:00Z", System.Globalization.CultureInfo.InvariantCulture), expiry.At);
        Assert.Equal(400, (await Call(services, "POST", "/__test/verification/expire?at=yesterday")).Context.Response.StatusCode);
        Assert.False((await Call(services, "GET", "/v1/x")).Handled);
    }

    [Fact]
    public async Task Without_seams_the_hooks_answer_not_found_or_not_wired()
    {
        var services = new ServiceCollection().BuildServiceProvider();
        Assert.Equal(404, (await Call(services, "GET", "/__test/sms?phone=01712345678")).Context.Response.StatusCode);
        Assert.Equal(404, (await Call(services, "GET", "/__test/sms?phone=x")).Context.Response.StatusCode);
        Assert.Equal("{\"pushes\":[]}", Contexts.Body((await Call(services, "GET", "/__test/pushes")).Context));
        Assert.Equal(501, (await Call(services, "POST", "/__test/verification/expire?at=2026-10-17T00:00:00%2B06:00")).Context.Response.StatusCode);
    }
}

public sealed class HealthAndMetricsTests
{
    [Fact]
    public async Task Readiness_names_every_dependency_that_failed()
    {
        var ok = await HealthEndpoints.Readiness([new HealthCheck("database", _ => Task.CompletedTask)], CancellationToken.None);
        Assert.Equal(200, ok.Status);
        var failed = await HealthEndpoints.Readiness(
            [new HealthCheck("database", _ => Task.CompletedTask), new HealthCheck("redis", _ => throw new InvalidOperationException("down"))], CancellationToken.None);
        Assert.Equal(503, failed.Status);
        Assert.Equal("""{"checks":{"redis":"unavailable"},"status":"unavailable"}""", JsonSerializer.Serialize(failed.Body));
    }

    [Fact]
    public async Task The_probe_succeeds_only_on_200()
    {
        Assert.True(await HealthEndpoints.Probe(new HttpClient(new StubHandler(_ => new HttpResponseMessage(HttpStatusCode.OK))), "http://x/healthz", TimeSpan.FromSeconds(1)));
        Assert.False(await HealthEndpoints.Probe(new HttpClient(new StubHandler(_ => new HttpResponseMessage(HttpStatusCode.ServiceUnavailable))), "http://x/healthz", TimeSpan.FromSeconds(1)));
        Assert.False(await HealthEndpoints.Probe(new HttpClient(new StubHandler(_ => throw new HttpRequestException("refused"))), "http://x/healthz", TimeSpan.FromSeconds(1)));
    }

    [Fact]
    public async Task Records_requests_by_route_and_renders_worker_metrics()
    {
        var metrics = new PaoMetrics();
        var context = Contexts.New("GET", "/v1/bookings/1");
        context.Edge().RouteTemplate = "/v1/bookings/{id}";
        await metrics.Record(context, c => { c.Response.StatusCode = 404; return Task.CompletedTask; });
        await metrics.Record(Contexts.New(), _ => Task.CompletedTask);
        metrics.Worker.JobFinished("outbox.purge_published", PAO.Infrastructure.Jobs.JobOutcome.Ok, TimeSpan.FromSeconds(1));
        metrics.Worker.JobFinished("outbox.purge_published", PAO.Infrastructure.Jobs.JobOutcome.Skipped, TimeSpan.Zero);
        metrics.Worker.EventDelivered("booking", "booking.BookingAccepted");
        metrics.Worker.EventFailed("booking", "booking.BookingAccepted", true);
        metrics.Worker.EventFailed("booking", "booking.BookingAccepted", false);
        metrics.Worker.TrackBacklog(_ => Task.FromResult<IReadOnlyList<OutboxBacklog>>([new OutboxBacklog("booking", 3, 1, 12.5)]));
        var scrape = Contexts.New("GET", "/metrics");
        scrape.RequestServices = new ServiceCollection().AddSingleton(metrics).BuildServiceProvider();
        Assert.True(await InternalServer.Metrics(scrape));
        var text = Contexts.Body(scrape);
        Assert.Contains("pao_http_requests_total{route=\"/v1/bookings/{id}\",method=\"GET\",status=\"404\"} 1", text, StringComparison.Ordinal);
        Assert.Contains("route=\"unmatched\"", text, StringComparison.Ordinal);
        Assert.Contains("pao_job_runs_total{name=\"outbox.purge_published\",outcome=\"skipped\"} 1", text, StringComparison.Ordinal);
        Assert.Contains("pao_outbox_pending_events{module=\"booking\"} 3", text, StringComparison.Ordinal);
        Assert.Contains("pao_outbox_delivery_failures_total{module=\"booking\",event=\"booking.BookingAccepted\",dead=\"true\"} 1", text, StringComparison.Ordinal);
    }

    [Fact]
    public async Task The_internal_server_chains_handlers_and_answers_404()
    {
        var services = new ServiceCollection().AddSingleton(new PaoMetrics()).BuildServiceProvider();
        await using var app = InternalServer.Build("127.0.0.1:0", services, web => web.UseTestServer(), InternalServer.Liveness, InternalServer.Metrics);
        await app.StartAsync();
        var client = app.GetTestClient();
        Assert.Equal("{\"status\":\"ok\"}\n", await client.GetStringAsync("/healthz"));
        Assert.Contains("process_", await client.GetStringAsync("/metrics"), StringComparison.Ordinal);
        var missing = await client.PostAsync("/healthz", null);
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
        Assert.Equal("404 page not found\n", await missing.Content.ReadAsStringAsync());
        await app.StopAsync();
    }
}

public sealed class AccessTests
{
    private sealed class Sample
    {
        [Customer(Permission = "booking:create")]
        public void Create() { }

        [AllowAnonymous]
        public void Open() { }

        [Admin]
        public void AnyAdmin() { }

        [AllUserType]
        public void Signed() { }

        [Merchant(Permission = "job:respond")]
        public void Respond() { }

        public void Undeclared() { }
    }

    [PermissionFromSpec]
    private sealed class FromSpec
    {
        public void Any() { }
    }

    private static ControllerActionDescriptor Action<T>(string method) => new()
    {
        MethodInfo = typeof(T).GetMethod(method)!,
        ControllerTypeInfo = typeof(T).GetTypeInfo(),
    };

    private static MatchedOperation Op(string? permission) => new(new OperationInfo
    {
        Id = "op",
        Method = "get",
        PathTemplate = "/x",
        Permission = permission,
        Public = false,
        Idempotent = false,
        Parameters = [],
    }, new Dictionary<string, string>());

    [Fact]
    public void Reads_requirements_from_the_attributes_and_the_spec()
    {
        Assert.Equal(new AccessRequirement(AccessKind.Permission, "booking:create"), AccessRequirement.For(Action<Sample>("Create"), null));
        Assert.Equal(AccessKind.Public, AccessRequirement.For(Action<Sample>("Open"), null).Kind);
        Assert.Equal(AccessKind.AnyAdminRole, AccessRequirement.For(Action<Sample>("AnyAdmin"), null).Kind);
        Assert.Equal(AccessKind.Authenticated, AccessRequirement.For(Action<Sample>("Signed"), null).Kind);
        Assert.Equal(AccessKind.Undeclared, AccessRequirement.For(Action<Sample>("Undeclared"), null).Kind);
        Assert.Equal(Audience.Merchant, new MerchantAttribute().Audience);
        Assert.Equal(Audience.Customer, new CustomerAttribute().Audience);
        Assert.Equal(Audience.Admin, new AdminAttribute().Audience);
        Assert.Equal(Audience.AllUserTypes, new AllUserTypeAttribute().Audience);
        Assert.Equal(AccessKind.Public, AccessRequirement.For(Action<FromSpec>("Any"), Op("public")).Kind);
        Assert.Equal(AccessKind.Authenticated, AccessRequirement.For(Action<FromSpec>("Any"), Op("authenticated")).Kind);
        Assert.Equal("audit:read", AccessRequirement.For(Action<FromSpec>("Any"), Op("audit:read")).Permission);
        Assert.Equal(AccessKind.Undeclared, AccessRequirement.For(Action<FromSpec>("Any"), null).Kind);
    }

    [Fact]
    public void Principals_come_from_verified_claims()
    {
        var id = Guid.NewGuid();
        var principal = Principal.From(new AccessClaims
        {
            Subject = id.ToString(),
            Roles = ["customer"],
            TokenId = "j",
            SessionId = UuidText.Nil,
            Version = 1,
            ExpiresAt = DateTimeOffset.UnixEpoch,
        });
        Assert.True(principal.HasRole("customer"));
        Assert.Equal(id.ToString(), principal.ToClaimsPrincipal().FindFirst("sub")!.Value);
        var context = Contexts.New();
        Assert.Throws<ApiError>(() => context.Caller());
        context.Edge().Principal = principal;
        Assert.Same(principal, context.Caller());
    }

    private sealed class Map : IErrorMap
    {
        public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError> { ["x.gone"] = new(410, "GONE", "Gone.") };
    }

    [ErrorMap(typeof(Map))]
    private sealed class Mapped
    {
        public void Act() { }
    }

    [Fact]
    public async Task The_exception_filter_applies_the_area_map_then_writes_the_envelope()
    {
        var http = Contexts.New();
        var context = new ExceptionContext(new ActionContext(http, new RouteData(), Action<Mapped>("Act")), [])
        {
            Exception = new PAO.Lib.Errors.DomainException("x.gone"),
        };
        await new ApiExceptionFilter(NullLogger<ApiExceptionFilter>.Instance).OnExceptionAsync(context);
        Assert.Equal(410, http.Response.StatusCode);
        Assert.True(context.ExceptionHandled);
        var plain = Contexts.New();
        await new ApiExceptionFilter(NullLogger<ApiExceptionFilter>.Instance).OnExceptionAsync(
            new ExceptionContext(new ActionContext(plain, new RouteData(), new ActionDescriptor()), []) { Exception = ApiErrors.NotFound });
        Assert.Equal(404, plain.Response.StatusCode);
    }

    [Fact]
    public void The_idempotency_hash_covers_method_path_and_body() =>
        Assert.Equal(
            RandomSecrets.Sha256Hex("POST /v1/customer/bookings\n{}"),
            IdempotencyFilter.RequestHash("POST", "/v1/customer/bookings", "{}"u8.ToArray()));
}
