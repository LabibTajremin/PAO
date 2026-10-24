using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Jobs;
using PAO.Infrastructure.Mediation;
using PAO.Infrastructure.Push;
using PAO.Infrastructure.Sms;
using PAO.Lib.Mediator;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed record Ping(string Text) : IQuery<string>;

public sealed class PingHandler : IRequestHandler<Ping, string>
{
    public Task<string> Handle(Ping request, CancellationToken cancellationToken) =>
        request.Text == "fail" ? throw new InvalidOperationException("fail") : Task.FromResult("pong " + request.Text);
}

public sealed class PingValidator : AbstractValidator<Ping>
{
    public PingValidator() => RuleFor(p => p.Text).NotEmpty();
}

public sealed record Orphan : IQuery<int>;

public sealed class MediatorTests
{
    private static IMediator Build()
    {
        var services = new ServiceCollection().AddLogging();
        services.AddScoped(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
        services.AddScoped(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddScoped<IMediator, Mediator>();
        services.AddScoped<IRequestHandler<Ping, string>, PingHandler>();
        services.AddScoped<IValidator<Ping>, PingValidator>();
        return services.BuildServiceProvider().CreateScope().ServiceProvider.GetRequiredService<IMediator>();
    }

    [Fact]
    public async Task Runs_the_handler_through_logging_and_validation()
    {
        var mediator = Build();
        Assert.Equal("pong a", await mediator.Send(new Ping("a")));
        Assert.Equal("pong b", await mediator.Send(new Ping("b")));
        var invalid = await Assert.ThrowsAsync<ApiError>(() => mediator.Send(new Ping(string.Empty)));
        Assert.Equal("text", invalid.Details!["field"]);
        await Assert.ThrowsAsync<InvalidOperationException>(() => mediator.Send(new Ping("fail")));
        await Assert.ThrowsAsync<InvalidOperationException>(() => mediator.Send(new Orphan()));
        await Assert.ThrowsAsync<ArgumentNullException>(() => mediator.Send<string>(null!));
    }

    [Fact]
    public void Registration_scans_handlers_validators_and_profiles()
    {
        var services = new ServiceCollection().AddMediator(typeof(MediatorTests).Assembly);
        Assert.Contains(services, d => d.ServiceType == typeof(IRequestHandler<Ping, string>));
        Assert.Contains(services, d => d.ServiceType == typeof(IValidator<Ping>));
        Assert.Contains(services, d => d.ServiceType == typeof(PAO.Lib.Mapping.IMappingProfile));
    }
}

public sealed class TestProfile : PAO.Lib.Mapping.IMappingProfile
{
    public void Configure(PAO.Lib.Mapping.MappingRegistry registry) => registry.Add<int, string>((i, _) => i.ToString(System.Globalization.CultureInfo.InvariantCulture));
}

public sealed class EventTests
{
    private static Envelope Envelope(string payload, string name = "booking.BookingAccepted") => new()
    {
        Id = Guid.NewGuid(),
        Module = "booking",
        Name = name,
        AggregateId = "b1",
        Payload = JsonDocument.Parse(payload).RootElement,
        OccurredAt = DateTimeOffset.UnixEpoch,
    };

    [Fact]
    public async Task Delivers_to_every_subscriber_and_reports_all_failures()
    {
        var bus = new EventBus();
        var seen = new List<string>();
        bus.Subscribe("booking.BookingAccepted", "notify", (e, _) => { seen.Add("notify"); return Task.CompletedTask; });
        bus.Subscribe("booking.BookingAccepted", "audit", (_, _) => throw new InvalidOperationException("audit down"));
        bus.Subscribe("booking.BookingAccepted", "rating", (_, _) => throw new InvalidOperationException("rating down"));
        var error = await Assert.ThrowsAsync<EventDeliveryException>(() => bus.Dispatch(Envelope("{}"), CancellationToken.None));
        Assert.Equal("audit: audit down\nrating: rating down", error.Message);
        Assert.Equal(["notify"], seen);
        await bus.Dispatch(Envelope("{}", "other.Event"), CancellationToken.None);
    }

    [Fact]
    public void Reads_payloads_like_go_json_decoding()
    {
        var payload = new EventPayload(Envelope("""{"id":"x","n":2,"t":"s","f":true,"g":false,"z":null}"""));
        Assert.Equal("x", payload.Id("id"));
        Assert.Equal(PAO.Infrastructure.Crypto.UuidText.Nil, payload.Id("missing"));
        Assert.Equal(2, payload.Number("n"));
        Assert.Equal(0, payload.Number("z"));
        Assert.Equal("s", payload.Text("t"));
        Assert.Equal(string.Empty, payload.Text("missing"));
        Assert.True(payload.Flag("f"));
        Assert.False(payload.Flag("g"));
        Assert.False(payload.Flag("missing"));
        Assert.False(payload.Flag("z"));
        Assert.Equal("decode booking.BookingAccepted: n is not a string", Assert.Throws<FormatException>(() => payload.Text("n")).Message);
        Assert.Throws<FormatException>(() => payload.Flag("t"));
        Assert.Throws<FormatException>(() => new EventPayload(Envelope("[]")));
    }

    [Fact]
    public void Schedules_daily_runs_on_dhaka_wall_clock_time()
    {
        var at = new DateTimeOffset(2026, 10, 17, 19, 0, 0, TimeSpan.Zero);
        Assert.Equal(new DateTimeOffset(2026, 10, 17, 21, 0, 0, TimeSpan.Zero), JobSchedule.NextDailyRun(at, 3, 0));
        Assert.Equal(new DateTimeOffset(2026, 10, 17, 20, 0, 0, TimeSpan.Zero), JobSchedule.NextDailyRun(at, 2, 0));
        Assert.Equal(TimeSpan.FromHours(2), JobSchedule.DailyAt(3, 0).DelayFrom(at));
        Assert.Equal(TimeSpan.FromSeconds(15), JobSchedule.Every(TimeSpan.FromSeconds(15)).DelayFrom(at));
    }
}

internal sealed class StubHandler(Func<HttpRequestMessage, HttpResponseMessage> answer) : HttpMessageHandler
{
    public List<string> Bodies { get; } = [];

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        Bodies.Add(request.Content is null ? string.Empty : await request.Content.ReadAsStringAsync(cancellationToken));
        return answer(request);
    }

    public static HttpResponseMessage Json(HttpStatusCode status, string body) =>
        new(status) { Content = new StringContent(body, Encoding.UTF8, "application/json") };
}

public sealed class SmsAndPushTests
{
    [Fact]
    public async Task Ssl_wireless_posts_the_gateway_fields_and_checks_its_status()
    {
        var answers = new Queue<HttpResponseMessage>([StubHandler.Json(HttpStatusCode.OK, """{"status_code":200}"""), StubHandler.Json(HttpStatusCode.OK, """{"status_code":4001}"""), StubHandler.Json(HttpStatusCode.BadGateway, "<html>")]);
        var stub = new StubHandler(_ => answers.Dequeue());
        var sms = new SslWirelessSmsSender(new HttpClient(stub), new SmsOptions { SslWirelessApiToken = "t", SslWirelessSid = "s" }, new SequenceIds(Guid.Parse("0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c")));
        await sms.Send("+8801712345678", "code 123456", CancellationToken.None);
        using var sent = JsonDocument.Parse(stub.Bodies[0]);
        Assert.Equal("8801712345678", sent.RootElement.GetProperty("msisdn").GetString());
        Assert.Equal("0190a5b27c1d7e3f8a9b", sent.RootElement.GetProperty("csms_id").GetString());
        Assert.Contains("status 4001", (await Assert.ThrowsAsync<HttpRequestException>(() => sms.Send("+880", "x", CancellationToken.None))).Message, StringComparison.Ordinal);
        Assert.Contains("http 502, status 0", (await Assert.ThrowsAsync<HttpRequestException>(() => sms.Send("+880", "x", CancellationToken.None))).Message, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Console_and_captured_sms_never_leave_the_process()
    {
        await new ConsoleSmsSender(NullLogger<ConsoleSmsSender>.Instance).Send("+880", "x", CancellationToken.None);
        var captured = new CapturedSmsSender();
        await captured.Send("+8801712345678", "first", CancellationToken.None);
        await captured.Send("+8801712345678", "second", CancellationToken.None);
        Assert.Equal("second", captured.Last("+8801712345678"));
        Assert.Null(captured.Last("+8801"));
    }

    [Fact]
    public async Task The_capture_pusher_keeps_recent_pushes_and_simulates_dead_tokens()
    {
        var pusher = new CapturePushSender(NullLogger<CapturePushSender>.Instance);
        var message = new PushMessage("t", "b", new Dictionary<string, string> { ["type"] = "x" });
        for (var i = 0; i < 1002; i++)
        {
            await pusher.Push(i == 0 ? "old" : "device", message, CancellationToken.None);
        }
        Assert.Equal(1000, pusher.SentTo("device").Count);
        Assert.Empty(pusher.SentTo("old"));
        await Assert.ThrowsAsync<InvalidPushTokenException>(() => pusher.Push("invalid-1", message, CancellationToken.None));
        await Assert.ThrowsAsync<HttpRequestException>(() => pusher.Push("broken-1", message, CancellationToken.None));
    }

    private static string AccountJson(string? tokenUri = null)
    {
        using var rsa = RSA.Create(2048);
        var account = new Dictionary<string, string> { ["project_id"] = "pao-test", ["client_email"] = "fcm@pao.test", ["private_key"] = rsa.ExportPkcs8PrivateKeyPem() };
        if (tokenUri is not null)
        {
            account["token_uri"] = tokenUri;
        }
        return JsonSerializer.Serialize(account);
    }

    [Fact]
    public async Task Fcm_uses_cached_service_account_tokens_and_maps_dead_tokens()
    {
        var statuses = new Queue<HttpStatusCode>([HttpStatusCode.OK, HttpStatusCode.NotFound, HttpStatusCode.BadRequest, HttpStatusCode.InternalServerError]);
        var tokenCalls = 0;
        var stub = new StubHandler(request => request.RequestUri!.Host == "oauth.test"
            ? StubHandler.Json(HttpStatusCode.OK, $$"""{"access_token":"at{{++tokenCalls}}","expires_in":120}""")
            : StubHandler.Json(statuses.Dequeue(), "fcm says no"));
        var clock = new FakeClock(DateTimeOffset.UnixEpoch);
        var account = ServiceAccount.Parse(AccountJson("https://oauth.test/token"));
        var tokens = new GoogleAccessTokens(new HttpClient(stub), account, clock);
        var fcm = new FcmPushSender(new HttpClient(stub), FcmPushSender.EndpointFor(account.ProjectId), tokens);
        var message = new PushMessage("t", "b", new Dictionary<string, string>());
        await fcm.Push("device", message, CancellationToken.None);
        await Assert.ThrowsAsync<InvalidPushTokenException>(() => fcm.Push("device", message, CancellationToken.None));
        await Assert.ThrowsAsync<InvalidPushTokenException>(() => fcm.Push("device", message, CancellationToken.None));
        Assert.Equal(1, tokenCalls);
        clock.Advance(TimeSpan.FromMinutes(2));
        Assert.Contains("fcm: 500 fcm says no", (await Assert.ThrowsAsync<HttpRequestException>(() => fcm.Push("device", message, CancellationToken.None))).Message, StringComparison.Ordinal);
        Assert.Equal(2, tokenCalls);
        Assert.Contains("\"android\":{\"priority\":\"high\"}", stub.Bodies[1], StringComparison.Ordinal);
    }

    [Fact]
    public async Task Token_failures_and_bad_key_files_are_reported()
    {
        var stub = new StubHandler(_ => StubHandler.Json(HttpStatusCode.Unauthorized, "{}"));
        var account = ServiceAccount.Parse(AccountJson());
        Assert.Equal("https://oauth2.googleapis.com/token", account.TokenUri);
        var tokens = new GoogleAccessTokens(new HttpClient(stub), account with { TokenUri = "https://oauth.test/token" }, new FakeClock(DateTimeOffset.UnixEpoch));
        await Assert.ThrowsAsync<HttpRequestException>(() => tokens.AccessToken(CancellationToken.None));
        var noExpiry = new GoogleAccessTokens(new HttpClient(new StubHandler(_ => StubHandler.Json(HttpStatusCode.OK, """{"access_token":"x"}"""))), account, new FakeClock(DateTimeOffset.UnixEpoch));
        Assert.Equal("x", await noExpiry.AccessToken(CancellationToken.None));
        Assert.Throws<FormatException>(() => ServiceAccount.Parse("""{"project_id":"p","client_email":1}"""));
    }
}
