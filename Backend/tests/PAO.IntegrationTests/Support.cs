using System.Collections;
using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core;
using PAO.Core.Registration;
using PAO.EF;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Redis;
using PAO.Infrastructure.Registration;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;
using PAO.TestKit;
using StackExchange.Redis;

namespace PAO.IntegrationTests;

/// <summary>A private migrated database per test class.</summary>
public sealed class MigratedDatabase : IAsyncLifetime
{
    public string Url { get; private set; } = string.Empty;

    public async ValueTask InitializeAsync() => Url = await TestDatabases.CreateMigrated();

    public async ValueTask DisposeAsync() => await TestDatabases.Drop(Url);
}

/// <summary>Builds the API and connections the way Program.cs does, on a test server.</summary>
public static class Hosts
{
    public static readonly PaoPaths Paths = PaoPaths.Resolve(AppContext.BaseDirectory, null);

    public static Hashtable Environment(string databaseUrl, string appEnv = "test")
    {
        var env = new Hashtable();
        foreach (var (k, v) in TestSettings.Environment(databaseUrl, appEnv))
        {
            env[k] = v;
        }
        return env;
    }

    public static async Task<WebApplication> Api(string databaseUrl, string appEnv = "test", Action<IServiceCollection>? configure = null)
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { ContentRootPath = AppContext.BaseDirectory });
        builder.WebHost.UseTestServer();
        var settings = builder.AddPaoSettings(Paths, Environment(databaseUrl, appEnv), "api");
        settings.Logging.WriteFiles = false;
        builder.Services
            .AddBuiltInServices(settings, Paths.Spec, typeof(ApiHost).Assembly)
            .AddCustomServices(settings, typeof(ApiHost).Assembly, typeof(Hosts).Assembly)
            .AddDatabase(settings)
            .AddRepositories()
            .AddAreas();
        builder.Services.AddControllers().AddApplicationPart(typeof(Hosts).Assembly);
        builder.Services.AddSingleton(new RedisKeys(TestEnvironment.Unique("t")));
        configure?.Invoke(builder.Services);
        var app = builder.Build();
        app.UseHttpEdge(settings);
        await app.StartAsync();
        return app;
    }

    public static string Token(IServiceProvider services, string[] roles, Guid? subject = null) =>
        services.GetRequiredService<TokenSigner>().Sign(new TokenRequest((subject ?? Guid.NewGuid()).ToString(), roles)).Token;

    public static HttpRequestMessage Request(HttpMethod method, string path, string? token = null, object? body = null)
    {
        var request = new HttpRequestMessage(method, path);
        if (token is not null)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
        if (body is not null)
        {
            request.Content = new StringContent(JsonSerializer.Serialize(body), System.Text.Encoding.UTF8, "application/json");
        }
        return request;
    }

    public static async Task<string> ErrorCode(HttpResponseMessage response) =>
        JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement.GetProperty("error").GetProperty("code").GetString()!;

    public static IConnectionMultiplexer Redis() => ConnectionMultiplexer.Connect(RedisUrl.Parse(TestEnvironment.RedisUrl));
}

/// <summary>Inserts a permission row in a command transaction; `Fail` throws after the insert.</summary>
public sealed record InsertPermission(string Name, bool Fail) : ICommand;

public sealed class InsertPermissionHandler(PaoDbContext db, IMediator mediator) : IRequestHandler<InsertPermission, Unit>
{
    public async Task<Unit> Handle(InsertPermission request, CancellationToken cancellationToken)
    {
        db.Permissions.Add(new PAO.EF.Identity.Permission { Name = request.Name, Description = "test" });
        await db.SaveChangesAsync(cancellationToken);
        if (request.Name.EndsWith("-outer", StringComparison.Ordinal))
        {
            await mediator.Send(new InsertPermission(request.Name.Replace("-outer", "-inner", StringComparison.Ordinal), false), cancellationToken);
        }
        return request.Fail ? throw new InvalidOperationException("rolled back") : Unit.Value;
    }
}

public sealed record CountPermissions(string Prefix) : IQuery<int>;

public sealed class CountPermissionsHandler(PaoDbContext db) : IRequestHandler<CountPermissions, int>
{
    public Task<int> Handle(CountPermissions request, CancellationToken cancellationToken) =>
        db.Permissions.CountAsync(p => p.Name.StartsWith(request.Prefix), cancellationToken);
}

public sealed class TestErrors : IErrorMap
{
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        ["test.gone"] = new(410, "GONE", "Gone."),
    };
}

/// <summary>Present in hosts whose createBooking is the edge tests' stand-in.</summary>
public sealed class EdgeTestRoutes;

/// <summary>Lets an action match only in hosts that registered <see cref="EdgeTestRoutes"/>.</summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class EdgeTestRouteAttribute : Attribute, Microsoft.AspNetCore.Mvc.ActionConstraints.IActionConstraint
{
    public int Order => 0;

    public bool Accept(Microsoft.AspNetCore.Mvc.ActionConstraints.ActionConstraintContext context) =>
        context.RouteContext.HttpContext.RequestServices.GetService<EdgeTestRoutes>() is not null;
}

/// <summary>Serves createBooking for the edge tests (idempotency, error maps, the mediator) ahead of Booking's own route.</summary>
[ApiController]
[ErrorMap(typeof(TestErrors))]
public sealed class TestBookingsController(IMediator mediator) : ControllerBase
{
    [HttpPost("/v1/customer/bookings", Order = -1)]
    [EdgeTestRoute]
    [Customer(Permission = "booking:create")]
    public async Task<IActionResult> Create([FromBody] JsonElement body)
    {
        var note = body.TryGetProperty("note", out var n) ? n.GetString() : null;
        return note switch
        {
            "fail" => throw new InvalidOperationException("server error"),
            "domain" => throw new DomainException("test.gone"),
            _ => StatusCode(201, new { count = await mediator.Send(new CountPermissions("booking")) }),
        };
    }
}

/// <summary>A context factory over fixed options, for tests that build services by hand.</summary>
public sealed class TestContextFactory(DbContextOptions<PaoDbContext> options) : IDbContextFactory<PaoDbContext>
{
    public PaoDbContext CreateDbContext() => new(options);
}
