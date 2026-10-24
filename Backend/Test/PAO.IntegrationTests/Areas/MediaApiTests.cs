using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.BackgroundJobs;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

public sealed class MediaApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private static readonly byte[] Jpeg = [.. Enumerable.Repeat((byte)0xff, 1024)];
    private readonly FakeAudit audit = new();
    private readonly FakeClock clock = new(DateTimeOffset.UtcNow);
    private AreaApi api = null!;

    public async ValueTask InitializeAsync() => api = await AreaApi.Start(database.Url, services =>
    {
        services.AddSingleton<IAuditSharedService>(audit);
        services.AddSingleton<IClock>(clock);
    });

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private static object JpegOf(string purpose, long size = 1024) => new { purpose, contentType = "image/jpeg", sizeBytes = size };

    private static async Task<HttpStatusCode> Put(string url, IReadOnlyDictionary<string, string> headers, byte[] body)
    {
        using var http = new HttpClient();
        using var content = new ByteArrayContent(body);
        foreach (var (k, v) in headers)
        {
            content.Headers.TryAddWithoutValidation(k, v);
        }
        using var response = await http.PutAsync(url, content);
        return response.StatusCode;
    }

    private static Dictionary<string, string> Headers(JsonElement ticket) =>
        ticket.GetProperty("headers").EnumerateObject().ToDictionary(p => p.Name, p => p.Value.GetString()!);

    private async Task<JsonElement> Ticket(string token, string app, object body)
    {
        var r = await api.Call(HttpMethod.Post, $"/v1/{app}/uploads", token, body);
        Assert.Equal(HttpStatusCode.Created, r.Status);
        return r.Body;
    }

    [Fact]
    public async Task A_provider_document_is_uploaded_confirmed_and_shown_with_an_audit_entry()
    {
        var provider = api.Token("provider");
        var ticket = await Ticket(provider, "provider", JpegOf("nid_front"));
        var mediaId = ticket.GetProperty("mediaId").GetString();
        var confirm = $"/v1/provider/uploads/{mediaId}/confirm";
        var early = await api.Call(HttpMethod.Post, confirm, provider);
        Assert.Equal("UPLOAD_NOT_FOUND", early.Body.GetProperty("error").GetProperty("code").GetString());
        Assert.Equal(HttpStatusCode.OK, await Put(ticket.GetProperty("uploadUrl").GetString()!, Headers(ticket), Jpeg));
        for (var i = 0; i < 2; i++)
        {
            var r = await api.Call(HttpMethod.Post, confirm, provider);
            Assert.Equal(HttpStatusCode.OK, r.Status);
            Assert.Equal("confirmed", r.Body.GetProperty("status").GetString());
        }
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, confirm, api.Token("provider"))).Status);
        var verifierId = Guid.NewGuid();
        var view = await api.Call(HttpMethod.Get, $"/v1/admin/documents/{mediaId}/view-url", api.Token(verifierId, "verifier"));
        Assert.Equal(HttpStatusCode.OK, view.Status);
        using (var http = new HttpClient())
        {
            Assert.Equal(HttpStatusCode.OK, (await http.GetAsync(view.Body.GetProperty("url").GetString())).StatusCode);
        }
        var entry = Assert.Single(await audit.ListForSubject("media", mediaId!, 10, CancellationToken.None));
        Assert.Equal(("media.document_viewed", verifierId, "verifier"), (entry.Action, entry.ActorId!.Value, entry.ActorRole));
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/admin/documents/{Guid.NewGuid()}/view-url", api.Token("verifier"))).Status);
    }

    [Fact]
    public async Task Each_app_keeps_its_upload_rules()
    {
        var customer = api.Token("customer");
        var ticket = await Ticket(customer, "customer", JpegOf("avatar"));
        Assert.Equal(HttpStatusCode.Forbidden, await Put(ticket.GetProperty("uploadUrl").GetString()!, Headers(ticket), Jpeg[..10]));
        var mismatch = await api.Call(HttpMethod.Post, $"/v1/customer/uploads/{ticket.GetProperty("mediaId").GetString()}/confirm", customer);
        Assert.Equal(HttpStatusCode.Conflict, mismatch.Status);
        object[] refused = [JpegOf("nid_front", 10), new { purpose = "avatar", contentType = "application/pdf", sizeBytes = 10 }, new { purpose = "avatar", contentType = "image/png", sizeBytes = 3 << 20 }];
        foreach (var body in refused)
        {
            var r = await api.Call(HttpMethod.Post, "/v1/customer/uploads", customer, body);
            Assert.Equal("UPLOAD_INVALID", r.Body.GetProperty("error").GetProperty("code").GetString());
        }
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"/v1/customer/uploads/{Guid.NewGuid()}/confirm", customer)).Status);
        var level2 = await api.Call(HttpMethod.Post, "/v1/provider/uploads", api.Token("provider"), JpegOf("level2_photo", 10));
        Assert.Equal("UPLOAD_INVALID", level2.Body.GetProperty("error").GetProperty("code").GetString());
        var photo = await Ticket(customer, "customer", JpegOf("complaint_photo"));
        Assert.Equal(HttpStatusCode.OK, await Put(photo.GetProperty("uploadUrl").GetString()!, Headers(photo), Jpeg));
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Post, $"/v1/customer/uploads/{photo.GetProperty("mediaId").GetString()}/confirm", customer)).Status);
    }

    [Fact]
    public async Task The_contract_serves_other_areas_and_orphans_are_purged()
    {
        using var scope = api.Services.CreateScope();
        var media = scope.ServiceProvider.GetRequiredService<IMediaSharedService>();
        var owner = Guid.NewGuid();
        var request = new UploadRequest { OwnerId = owner, Purpose = MediaPurpose.Level2Photo, ContentType = "image/jpeg", SizeBytes = Jpeg.Length };
        var kept = await media.CreateUploadUrl(request, CancellationToken.None);
        Assert.Equal(HttpStatusCode.OK, await Put(kept.Url, kept.Headers, Jpeg));
        Assert.True((await media.ConfirmUpload(owner, kept.MediaId, CancellationToken.None)).Confirmed);
        await media.MarkAttached(kept.MediaId, CancellationToken.None);
        var orphan = await media.CreateUploadUrl(request, CancellationToken.None);
        await Reason(MediaErrors.UploadInvalid, () => media.CreateUploadUrl(request with { Purpose = MediaPurpose.Avatar }, CancellationToken.None));
        await Reason(MediaErrors.NotUploaded, () => media.ConfirmUpload(owner, orphan.MediaId, CancellationToken.None));
        await Reason(MediaErrors.NotFound, () => media.GetViewUrl(new ViewRequest { MediaId = orphan.MediaId, ViewerId = owner, ViewerRole = "v" }, CancellationToken.None));
        var url = await media.GetViewUrl(new ViewRequest { MediaId = kept.MediaId, ViewerId = owner, ViewerRole = "verifier" }, CancellationToken.None);
        Assert.Equal(clock.Now + TimeSpan.FromMinutes(5), url.ExpiresAt);
        clock.Advance(TimeSpan.FromHours(25));
        await new MediaOrphanPurgeJob(api.Services.GetRequiredService<IServiceScopeFactory>()).Run(CancellationToken.None);
        await Reason(MediaErrors.NotFound, () => media.GetObject(orphan.MediaId, CancellationToken.None));
        Assert.Equal(MediaPurpose.Level2Photo, (await media.GetObject(kept.MediaId, CancellationToken.None)).Purpose);
        await media.Delete(kept.MediaId, CancellationToken.None);
        await Reason(MediaErrors.NotFound, () => media.MarkAttached(kept.MediaId, CancellationToken.None));
        await Reason(MediaErrors.NotFound, () => media.Delete(kept.MediaId, CancellationToken.None));
    }

    [Fact]
    public async Task Deleted_accounts_lose_their_files_documents_only_with_the_retention_purge()
    {
        var owner = Guid.NewGuid();
        var token = api.Token(owner, "provider");
        var avatar = (await Ticket(token, "provider", JpegOf("avatar"))).GetProperty("mediaId").GetString()!;
        var selfie = (await Ticket(token, "provider", JpegOf("selfie"))).GetProperty("mediaId").GetString()!;
        var bus = new EventBus();
        foreach (var subscriptions in api.Services.GetServices<IEventSubscriptions>())
        {
            subscriptions.Subscribe(bus);
        }
        var payload = JsonSerializer.SerializeToElement(new { accountId = owner });
        await bus.Dispatch(new Envelope { Id = Guid.NewGuid(), Module = "identity", Name = IdentityEvents.AccountDeleted, AggregateId = owner.ToString(), Payload = payload, OccurredAt = clock.Now }, CancellationToken.None);
        using var scope = api.Services.CreateScope();
        var media = scope.ServiceProvider.GetRequiredService<IMediaSharedService>();
        await Reason(MediaErrors.NotFound, () => media.GetObject(Guid.Parse(avatar), CancellationToken.None));
        Assert.Equal(MediaPurpose.Selfie, (await media.GetObject(Guid.Parse(selfie), CancellationToken.None)).Purpose);
        await media.DeleteOwnerFiles(owner, CancellationToken.None);
        await Reason(MediaErrors.NotFound, () => media.GetObject(Guid.Parse(selfie), CancellationToken.None));
    }

    private static async Task Reason(string reason, Func<Task> call) =>
        Assert.Equal(reason, (await Assert.ThrowsAsync<DomainException>(call)).Reason);
}
