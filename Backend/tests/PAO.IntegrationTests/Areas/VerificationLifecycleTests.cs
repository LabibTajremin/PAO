using System.Globalization;
using System.Net;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.BackgroundJobs;
using PAO.Core.Areas.Verification.Services.Shared;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Identity;

namespace PAO.IntegrationTests.Areas;

public sealed class VerificationLifecycleTests(MigratedDatabase database) : VerificationHarness(database), IClassFixture<MigratedDatabase>
{
    private static string At(DateTimeOffset t) => t.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture);

    private IServiceScopeFactory Scopes => Api.Services.GetRequiredService<IServiceScopeFactory>();

    private async Task<int> Level(Guid id)
    {
        using var scope = Api.Services.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<IVerificationSharedService>().GetLevel(id, CancellationToken.None);
    }

    [Fact]
    public async Task Level2_fails_cools_off_then_passes()
    {
        var p = await Verified();
        const string sessions = "/v1/admin/level2-sessions";
        var body = new { providerId = p.Id, serviceId = Catalog.Electrician, scheduledAt = At(Clock.Now.AddHours(48)), location = " PAO office, Gulshan 1 " };
        var created = await Api.Call(HttpMethod.Post, sessions, Verifier, body);
        Assert.Equal(HttpStatusCode.Created, created.Status);
        Assert.Equal("PAO office, Gulshan 1", created.Body.GetProperty("location").GetString());
        var first = created.Body.GetProperty("id").GetString();
        var next = await Api.Call(HttpMethod.Get, "/v1/provider/verification", Api.Token(p.Id, "provider"));
        Assert.Equal(first, next.Body.GetProperty("level2").GetProperty("nextSession").GetProperty("id").GetString());
        var photo = Media.Add(p.Id, "level2_photo");
        var fail = new { result = "fail", checklist = new[] { new { item = "Safe wiring", passed = false } }, notes = "Unsafe joints", visitLocation = new { lat = 23.79, lng = 90.41 }, photoMediaIds = new[] { photo } };
        var result = $"{sessions}/{first}/result";
        Assert.Equal("fail", (await Api.Call(HttpMethod.Post, result, Verifier, fail)).Body.GetProperty("result").GetString());
        Assert.Equal("SESSION_CLOSED", Code(await Api.Call(HttpMethod.Post, result, Verifier, fail)));
        Assert.Equal("LEVEL2_COOLING_OFF", Code(await Api.Call(HttpMethod.Post, sessions, Verifier, body)));
        var cooling = await Api.Call(HttpMethod.Get, "/v1/provider/verification", Api.Token(p.Id, "provider"));
        Assert.True(cooling.Body.GetProperty("level2").TryGetProperty("retryAfter", out _));
        Assert.False(cooling.Body.GetProperty("level2").GetProperty("eligible").GetBoolean());
        Clock.Advance(TimeSpan.FromDays(15));
        var again = await Api.Call(HttpMethod.Post, sessions, Verifier, body with { scheduledAt = At(Clock.Now.AddHours(1)) });
        var second = again.Body.GetProperty("id").GetString();
        var bad = new { result = "pass", checklist = Array.Empty<object>(), photoMediaIds = new[] { Media.Add(Guid.NewGuid(), "level2_photo") } };
        Assert.Equal("UPLOAD_INVALID", Code(await Api.Call(HttpMethod.Post, $"{sessions}/{second}/result", Verifier, bad)));
        var pass = new { result = "pass", checklist = new[] { new { item = "Safe wiring", passed = true } } };
        var passed = await Api.Call(HttpMethod.Post, $"{sessions}/{second}/result", Verifier, pass);
        Assert.Equal(HttpStatusCode.OK, passed.Status);
        var level2 = await Api.Call(HttpMethod.Get, "/v1/provider/verification", Api.Token(p.Id, "provider"));
        Assert.Equal((2, "verified_pro"), (level2.Body.GetProperty("level").GetInt32(), level2.Body.GetProperty("badge").GetString()));
        await ListsAndLooksUp(p.Id, first);
        var stranger = body with { providerId = Guid.NewGuid(), location = "Office", scheduledAt = At(Clock.Now.AddHours(1)) };
        Assert.Equal("LEVEL2_NOT_ELIGIBLE", Code(await Api.Call(HttpMethod.Post, sessions, Verifier, stranger)));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Api.Call(HttpMethod.Post, sessions, Verifier, stranger with { serviceId = Guid.NewGuid() })).Status);
        Assert.Equal("VALIDATION_FAILED", Code(await Api.Call(HttpMethod.Post, sessions, Verifier, body with { scheduledAt = At(Clock.Now.AddHours(-1)) })));
        Assert.Equal("VALIDATION_FAILED", Code(await Api.Call(HttpMethod.Post, sessions, Verifier, body with { location = "  " })));
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.outbox WHERE aggregate_id = '{p.Id}' AND event_name = 'verification.Level2SessionScheduled' AND payload->>'scheduledAt' NOT LIKE '%.%' AND payload->>'sessionId' = '{first}'"));
    }

    private async Task ListsAndLooksUp(Guid id, string? first)
    {
        const string sessions = "/v1/admin/level2-sessions";
        var pass = new { result = "pass", checklist = Array.Empty<object>() };
        var list = $"{sessions}?limit=1&status=completed";
        var page = await Api.Call(HttpMethod.Get, $"{list}&providerId={id}", Verifier);
        Assert.Equal(1, page.Body.GetProperty("items").GetArrayLength());
        var rest = await Api.Call(HttpMethod.Get, $"{list}&providerId={id}&cursor={page.Body.GetProperty("nextCursor").GetString()}", Verifier);
        Assert.Equal(1, rest.Body.GetProperty("items").GetArrayLength());
        Assert.False(rest.Body.TryGetProperty("nextCursor", out _));
        Assert.Equal("Unsafe joints", (await Api.Call(HttpMethod.Get, $"{sessions}/{first}", Verifier)).Body.GetProperty("notes").GetString());
        Assert.Equal(HttpStatusCode.NotFound, (await Api.Call(HttpMethod.Get, $"{sessions}/{Guid.NewGuid()}", Verifier)).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await Api.Call(HttpMethod.Post, $"{sessions}/{Guid.NewGuid()}/result", Verifier, pass)).Status);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Api.Call(HttpMethod.Get, $"{sessions}?cursor=%25", Verifier)).Status);
    }

    [Fact]
    public async Task Expiry_reminds_once_then_drops_the_level()
    {
        var p = await Verified();
        var expires = await Sql(db => Task.FromResult(db.Set<PAO.EF.Verification.VerificationItemRecord>().Single(i => i.ProviderId == p.Id && i.ItemType == "police_clearance").ExpiresAt!.Value));
        Clock.Now = expires - TimeSpan.FromDays(29.5);
        var reminders = new ExpiryRemindersJob(Scopes);
        Assert.Equal("verification.expiry_reminders", reminders.Name);
        await reminders.Run(CancellationToken.None);
        await reminders.Run(CancellationToken.None);
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.outbox WHERE aggregate_id = '{p.Id}' AND event_name = 'verification.DocumentExpiring'"));
        var expire = new ExpireDocumentsJob(Scopes);
        await expire.Run(CancellationToken.None);
        Assert.Equal(1, await Level(p.Id));
        using (var scope = Api.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<IDocumentExpiry>().ExpireDocumentsAt(expires, CancellationToken.None);
        }
        var st = await Api.Call(HttpMethod.Get, "/v1/provider/verification", Api.Token(p.Id, "provider"));
        Assert.Equal((0, false), (st.Body.GetProperty("level").GetInt32(), st.Body.GetProperty("canReceiveBookings").GetBoolean()));
        Assert.Equal("expired", st.Body.GetProperty("items")[2].GetProperty("status").GetString());
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.outbox WHERE aggregate_id = '{p.Id}' AND event_name = 'verification.DocumentExpired'"));
    }

    [Fact]
    public async Task A_ban_blocks_bookings_and_the_nid()
    {
        var p = await Verified();
        using var scope = Api.Services.CreateScope();
        var verification = scope.ServiceProvider.GetRequiredService<IVerificationSharedService>();
        await AccountStatus(p.Id, "suspended");
        Assert.False(await verification.CanReceiveBookings(p.Id, null, CancellationToken.None));
        await AccountStatus(p.Id, "banned");
        await AccountStatus(p.Id, "active");
        Assert.True(await verification.CanReceiveBookings(p.Id, null, CancellationToken.None));
        var other = Guid.NewGuid();
        Merchants.Add(other, Catalog.Electrician);
        var nid = new { nidNumber = "1712345678", frontMediaId = Media.Add(other, "nid_front"), backMediaId = Media.Add(other, "nid_back") };
        var r = await Put("nid", Api.Token(other, "provider"), nid);
        Assert.Equal((HttpStatusCode.Forbidden, "NID_BLOCKED"), (r.Status, Code(r)));
        await AccountStatus(Guid.NewGuid(), "banned");
        // The other tests of this class enrol with the same NID.
        await Sql(db => db.Database.ExecuteSqlRawAsync("DELETE FROM verification.blocked_nids"));
    }

    [Fact]
    public async Task Closed_accounts_keep_documents_for_the_retention_period_then_lose_them()
    {
        var p = await Verified();
        var sessions = "/v1/admin/level2-sessions";
        var s = await Api.Call(HttpMethod.Post, sessions, Verifier, new { providerId = p.Id, serviceId = Catalog.Electrician, scheduledAt = At(Clock.Now.AddHours(1)), location = "Banani" });
        var kept = Media.Add(p.Id, "level2_photo");
        var gone = Media.Add(p.Id, "level2_photo");
        var body = new { result = "retest", checklist = Array.Empty<object>(), photoMediaIds = new[] { kept, gone } };
        Assert.Equal(HttpStatusCode.OK, (await Api.Call(HttpMethod.Post, $"{sessions}/{s.Body.GetProperty("id").GetString()}/result", Verifier, body)).Status);
        Media.Objects.TryRemove(gone, out _);
        await Deliver(IdentityEvents.AccountDeleted, new { accountId = p.Id });
        await Deliver(IdentityEvents.AccountDeleted, new { accountId = p.Id });
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.closed_accounts WHERE provider_id = '{p.Id}'"));
        var purge = new PurgeClosedAccountsJob(Scopes);
        Clock.Advance(TimeSpan.FromDays(364));
        await purge.Run(CancellationToken.None);
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.levels WHERE provider_id = '{p.Id}'"));
        Clock.Advance(TimeSpan.FromDays(2));
        await purge.Run(CancellationToken.None);
        foreach (var table in new[] { "items", "documents", "nid_records", "levels", "level2_sessions", "closed_accounts" })
        {
            Assert.Equal(0, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.{table} WHERE provider_id = '{p.Id}'"));
        }
        Assert.Contains(kept, Media.Deleted);
        Assert.Contains(p.Id, Media.OwnersPurged);
    }
}
