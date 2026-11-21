using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Identity.Services;
using PAO.Core.Areas.Verification.Services.Shared;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Merchant;

namespace PAO.IntegrationTests.Areas;

public sealed class VerificationFlowTests(MigratedDatabase database) : VerificationHarness(database), IClassFixture<MigratedDatabase>
{
    private static string[] Strings(JsonElement e) => [.. e.EnumerateArray().Select(x => x.GetString()!)];

    [Fact]
    public async Task An_enrolment_reaches_level_one()
    {
        var p = await Enrolled();
        Assert.Equal(["nid", "selfie", "police_clearance"], Merchants.Steps[p.Id]);
        var q = await Api.Call(HttpMethod.Get, $"/v1/admin/verifications?serviceId={Catalog.Electrician}&itemType=nid", Verifier);
        var row = Assert.Single(q.Body.GetProperty("items").EnumerateArray());
        Assert.Equal("Rahim Uddin", row.GetProperty("name").GetString());
        Assert.Equal(7, row.GetProperty("pendingItems").GetArrayLength());
        Assert.Equal("Electrician", row.GetProperty("services")[0].GetProperty("name").GetProperty("en").GetString());
        var skill = await Api.Call(HttpMethod.Get, $"/v1/admin/verifications?serviceId={Catalog.Electrician}&itemType=skill_proof", Verifier);
        Assert.Equal(0, skill.Body.GetProperty("items").GetArrayLength());
        var path = $"/v1/admin/verifications/{p.Id}";
        var review = await Api.Call(HttpMethod.Get, path, Verifier);
        Assert.Equal("1712345678", review.Body.GetProperty("profile").GetProperty("nidNumber").GetString());
        Assert.Equal("manual_review", review.Body.GetProperty("faceMatch").GetString());
        var items = review.Body.GetProperty("items");
        Assert.Equal(["nid_back", "nid_front"], items[0].GetProperty("documents").EnumerateArray().Select(d => d.GetProperty("kind").GetString()).Order());
        Assert.Equal("Karim", items[4].GetProperty("fields").GetProperty("name").GetString());
        Assert.Equal("23.790000", items[6].GetProperty("fields").GetProperty("homeLat").GetString());
        Assert.Equal(HttpStatusCode.OK, (await Api.Call(HttpMethod.Post, $"{path}/items/selfie/reject", Verifier, new { reason = "Face not visible" })).Status);
        var status = await Api.Call(HttpMethod.Get, "/v1/provider/verification", p.Token);
        Assert.Equal((0, false), (status.Body.GetProperty("level").GetInt32(), status.Body.GetProperty("canReceiveBookings").GetBoolean()));
        Assert.Equal("Face not visible", status.Body.GetProperty("items")[1].GetProperty("rejectionReason").GetString());
        Assert.Equal("ITEM_NOT_PENDING", Code(await Api.Call(HttpMethod.Post, $"{path}/items/selfie/approve", Verifier)));
        await Put("selfie", p.Token, new { mediaId = Media.Add(p.Id, "selfie") });
        foreach (var item in new[] { "nid", "selfie", "police_clearance", "address", "emergency_contact", "service_area", "code_of_conduct" })
        {
            Assert.Equal(HttpStatusCode.OK, (await Api.Call(HttpMethod.Post, $"{path}/items/{item}/approve", Verifier)).Status);
        }
        var level1 = await Api.Call(HttpMethod.Get, "/v1/provider/verification", p.Token);
        Assert.Equal((1, "verified", true, true), (level1.Body.GetProperty("level").GetInt32(), level1.Body.GetProperty("badge").GetString(),
            level1.Body.GetProperty("canReceiveBookings").GetBoolean(), level1.Body.GetProperty("level2").GetProperty("eligible").GetBoolean()));
        Assert.True(level1.Body.GetProperty("items")[2].TryGetProperty("expiresAt", out _));
        await TheContractAnswers(p.Id);
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.outbox WHERE aggregate_id = '{p.Id}' AND event_name = 'verification.ProviderLevelChanged'"));
        Assert.Equal(1, await Count($"SELECT count(*)::int AS \"Value\" FROM verification.outbox WHERE aggregate_id = '{p.Id}' AND event_name = 'verification.DocumentRejected'"));
    }

    private async Task TheContractAnswers(Guid id)
    {
        using var scope = Api.Services.CreateScope();
        var verification = scope.ServiceProvider.GetRequiredService<IVerificationSharedService>();
        var none = CancellationToken.None;
        Assert.True(await verification.CanReceiveBookings(id, null, none));
        Assert.True(await verification.CanReceiveBookings(id, Catalog.Electrician, none));
        Assert.False(await verification.CanReceiveBookings(id, Catalog.Gas, none));
        Assert.Equal(0, await verification.GetLevel(Guid.NewGuid(), none));
        Assert.Equal(1, await scope.ServiceProvider.GetRequiredService<ILevelReader>().GetLevel(id, none));
        Assert.Equal(new Dictionary<Guid, int> { [id] = 1 }, await verification.GetLevels([id, Guid.NewGuid()], none));
        var items = await verification.GetItems(id, none);
        Assert.Equal(["address", "code_of_conduct", "emergency_contact", "nid", "police_clearance", "selfie", "service_area"], items.Select(i => i.Type));
        Assert.True(await verification.CountPendingReviews(none) >= 0);
    }

    [Fact]
    public async Task Document_steps_are_validated()
    {
        var id = Guid.NewGuid();
        var token = Api.Token(id, "provider");
        Merchants.Add(id, Catalog.Electrician, full: false);
        var selfie = Media.Add(id, "selfie");
        var old = Date(Clock.Now.AddYears(-2));
        (string Step, object Body, string Code)[] cases =
        [
            ("selfie", new { mediaId = Media.Add(Guid.NewGuid(), "selfie") }, "UPLOAD_INVALID"),
            ("selfie", new { mediaId = Guid.NewGuid() }, "UPLOAD_INVALID"),
            ("selfie", new { mediaId = Media.Add(id, "selfie", confirmed: false) }, "UPLOAD_INVALID"),
            ("police-clearance", new { mediaId = selfie, issueDate = Date(Clock.Now) }, "UPLOAD_INVALID"),
            ("police-clearance", new { mediaId = selfie, issueDate = old }, "CLEARANCE_TOO_OLD"),
            ("skill-proof", new { mediaIds = Array.Empty<Guid>() }, "VALIDATION_FAILED"),
            ("nid", new { nidNumber = "12", frontMediaId = selfie, backMediaId = selfie }, "VALIDATION_FAILED"),
        ];
        foreach (var (step, body, code) in cases)
        {
            Assert.Equal(code, Code(await Put(step, token, body)));
        }
        Assert.Equal(HttpStatusCode.InternalServerError, (await Put("selfie", token, new { mediaId = Media.Broken })).Status);
        var proof = await Put("skill-proof", token, new { mediaIds = new[] { Media.Add(id, "skill_proof") } });
        Assert.Equal(HttpStatusCode.OK, proof.Status);
        Assert.Equal("skill_proof", proof.Body.GetProperty("steps")[0].GetProperty("step").GetString());
        Merchants.Incomplete.Add(id);
        Assert.Equal("ENROLMENT_INCOMPLETE", Code(await Api.Call(HttpMethod.Post, "/v1/provider/enrolment/submit", token)));
        Assert.Equal(HttpStatusCode.NotFound, (await Api.Call(HttpMethod.Get, $"/v1/admin/verifications/{Guid.NewGuid()}", Verifier)).Status);
        var review = await Api.Call(HttpMethod.Get, $"/v1/admin/verifications/{id}", Verifier);
        Assert.Equal(("0001-01-01", "not_run"), (review.Body.GetProperty("profile").GetProperty("dateOfBirth").GetString(), review.Body.GetProperty("faceMatch").GetString()));
        Assert.False(review.Body.GetProperty("profile").TryGetProperty("nidNumber", out _));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Api.Call(HttpMethod.Post, $"/v1/admin/verifications/{id}/items/nid/reject", Verifier, new { reason = "   " })).Status);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await Api.Call(HttpMethod.Get, "/v1/admin/verifications?cursor=%25", Verifier)).Status);
        Assert.Equal(HttpStatusCode.Forbidden, (await Api.Call(HttpMethod.Get, "/v1/admin/verifications", token)).Status);
    }

    [Fact]
    public async Task A_clearance_issued_today_in_dhaka_after_18_utc_is_accepted()
    {
        Clock.Now = DateTimeOffset.Parse("2026-10-11T20:00:00Z", System.Globalization.CultureInfo.InvariantCulture);
        var id = Guid.NewGuid();
        Merchants.Add(id, Catalog.Electrician);
        var r = await Put("police-clearance", Api.Token(id, "provider"), new { mediaId = Media.Add(id, "police_clearance"), issueDate = "2026-10-12" });
        Assert.Equal(HttpStatusCode.OK, r.Status);
    }

    [Fact]
    public async Task The_queue_pages_and_profile_changes_go_back_to_review()
    {
        var first = await Enrolled(Catalog.Gas);
        Clock.Advance(TimeSpan.FromMinutes(1));
        var second = await Enrolled(Catalog.Gas, "1234567890123");
        var url = $"/v1/admin/verifications?limit=1&serviceId={Catalog.Gas}";
        var page = await Api.Call(HttpMethod.Get, url, Verifier);
        Assert.Equal(first.Id.ToString(), page.Body.GetProperty("items")[0].GetProperty("providerId").GetString());
        Assert.Equal("Gas", page.Body.GetProperty("items")[0].GetProperty("services")[0].GetProperty("name").GetProperty("en").GetString());
        var next = await Api.Call(HttpMethod.Get, $"{url}&cursor={page.Body.GetProperty("nextCursor").GetString()}", Verifier);
        Assert.Equal(second.Id.ToString(), next.Body.GetProperty("items")[0].GetProperty("providerId").GetString());
        Assert.False(next.Body.TryGetProperty("nextCursor", out _));
        await Api.Call(HttpMethod.Post, $"/v1/admin/verifications/{first.Id}/items/nid/approve", Verifier);
        await Api.Call(HttpMethod.Post, $"/v1/admin/verifications/{first.Id}/items/address/approve", Verifier);
        await StepSaved(first.Id, "personal");
        await StepSaved(first.Id, "selfie");
        var items = (await Api.Call(HttpMethod.Get, "/v1/provider/verification", first.Token)).Body.GetProperty("items");
        Assert.Equal(["pending", "pending"], new[] { items[0], items[3] }.Select(i => i.GetProperty("status").GetString()));
        Merchants.Profiles.TryRemove(first.Id, out _);
        await Assert.ThrowsAsync<EventDeliveryException>(() => StepSaved(first.Id, "area"));
        await Assert.ThrowsAsync<EventDeliveryException>(() => Deliver(MerchantEvents.EnrolmentStepSaved, "not an object"));
        Assert.True(Strings(page.Body.GetProperty("items")[0].GetProperty("pendingItems")).Contains("nid"));
    }
}
