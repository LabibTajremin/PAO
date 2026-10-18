using System.Collections.Concurrent;
using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Lib.Areas.Audit;

namespace PAO.IntegrationTests.Areas;

/// <summary>Stands in for the Audit area, which is ported in parallel.</summary>
public sealed class FakeAudit : IAuditSharedService
{
    public ConcurrentQueue<AuditEntry> Entries { get; } = new();

    public Task Record(AuditEntry entry, CancellationToken cancellationToken)
    {
        Entries.Enqueue(entry);
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<AuditEntry>> ListForSubject(string subjectType, string subjectId, int limit, CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyList<AuditEntry>>([.. Entries.Where(e => e.SubjectType == subjectType && e.SubjectId == subjectId).Take(limit)]);
}

/// <summary>An API on a private database with JSON helpers.</summary>
public sealed class AreaApi : IAsyncDisposable
{
    private AreaApi(WebApplication app)
    {
        App = app;
        Client = app.GetTestClient();
    }

    public WebApplication App { get; }

    public HttpClient Client { get; }

    public IServiceProvider Services => App.Services;

    public static async Task<AreaApi> Start(string databaseUrl, Action<IServiceCollection>? configure = null) =>
        new(await Hosts.Api(databaseUrl, configure: configure));

    public string Token(params string[] roles) => Hosts.Token(Services, roles);

    public string Token(Guid subject, params string[] roles) => Hosts.Token(Services, roles, subject);

    public async Task<(HttpStatusCode Status, JsonElement Body)> Call(HttpMethod method, string path, string? token, object? body = null)
    {
        using var response = await Client.SendAsync(Hosts.Request(method, path, token, body));
        var text = await response.Content.ReadAsStringAsync();
        return (response.StatusCode, text.Length == 0 ? default : JsonDocument.Parse(text).RootElement.Clone());
    }

    public async ValueTask DisposeAsync() => await App.DisposeAsync();
}
