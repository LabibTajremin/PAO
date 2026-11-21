using System.Net;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Verification.Services;
using PAO.EF;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;
using static PAO.IntegrationTests.Areas.MerchantSteps;

namespace PAO.IntegrationTests.Areas;

public sealed class MerchantEnrolmentTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private const string Verify = "/v1/provider/enrolment/emergency-contact/verify";
    private PeopleApi api = null!;

    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(database.Url);

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    [Fact]
    public async Task Keeps_the_wizard_resumable_and_submits()
    {
        var (id, token) = await api.Enrol("01712345678", "male", Electrician);
        var contact = new { name = "Karim Uddin", relation = "Brother", phone = "01812345678" };
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/provider/enrolment/emergency-contact", token, contact)).Status);
        Assert.Equal("OTP_INVALID", PeopleApi.Code((await api.Call(HttpMethod.Post, Verify, token, new { code = "000000" })).Body));
        var r = await api.Call(HttpMethod.Post, Verify, token, new { code = api.LastCode("01812345678") });
        Assert.Equal(HttpStatusCode.OK, r.Status);
        var done = Done(r.Body);
        Assert.True(done["personal"] && done["emergency_contact"] && !done["nid"]);
        Assert.False(r.Body.GetProperty("complete").GetBoolean());
        var coc = await api.Call(HttpMethod.Put, "/v1/provider/enrolment/code-of-conduct", token, new { version = "2026-10", accepted = true });
        Assert.True(Done(coc.Body)["code_of_conduct"]);
        Assert.Equal(9, (await api.Call(HttpMethod.Get, "/v1/provider/enrolment", token)).Body.GetProperty("steps").GetArrayLength());
        var incomplete = await Assert.ThrowsAsync<DomainException>(() => api.Merchants(async m => { await m.MarkSubmitted(id, CancellationToken.None); return 0; }));
        Assert.Equal(MerchantErrors.EnrolmentIncomplete, incomplete.Reason);
        foreach (var step in new[] { "nid", "selfie", "police_clearance" })
        {
            await api.Merchants(m => m.MarkStepDone(id, step, CancellationToken.None));
        }
        await api.Merchants(async m => { await m.MarkSubmitted(id, CancellationToken.None); return 0; });
        var status = await api.Merchants(m => m.Enrolment(id, CancellationToken.None));
        Assert.True(status.Complete && status.Submitted);
        var p = await api.Merchants(m => m.GetMerchant(id, CancellationToken.None));
        Assert.Equal(("Rahim Uddin", 23.7937, "+8801812345678", new DateOnly(1990, 4, 12)), (p.FullName, p.HomeBase!.Lat, p.EmergencyContact!.Phone, p.DateOfBirth!.Value));
        var missing = await Assert.ThrowsAsync<DomainException>(() => api.Merchants(m => m.GetMerchant(Guid.NewGuid(), CancellationToken.None)));
        Assert.Equal(MerchantErrors.NotFound, missing.Reason);
        Assert.False((await api.Merchants(m => m.Enrolment(Guid.NewGuid(), CancellationToken.None))).Complete);
        var query = new MerchantQuery { Id = id, Text = " RAHIM ", Status = "pending", Level = 0, Flagged = false, Limit = 5 };
        var found = Assert.Single(await api.Merchants(m => m.SearchMerchants(query, CancellationToken.None)));
        Assert.Equal((id, Electrician, false), (found.Id, found.ServiceIds.Single(), found.Online));
        Assert.Empty(await api.Merchants(m => m.SearchMerchants(query with { Text = @"rahim_%\" }, CancellationToken.None)));
        var after = query with { Text = string.Empty, AfterAt = DateTimeOffset.UtcNow.AddDays(1), AfterId = Guid.NewGuid() };
        Assert.Contains(await api.Merchants(m => m.SearchMerchants(after, CancellationToken.None)), r => r.Id == id);
        Assert.Single(await api.Merchants(m => m.SearchMerchants(new MerchantQuery { Id = id, Text = string.Empty, Status = string.Empty, Limit = 5 }, CancellationToken.None)));
    }

    [Fact]
    public async Task Serves_verification_through_the_real_merchant_contract()
    {
        var (id, _) = await api.Enrol("01712345690", "female", Electrician);
        var batch = await api.Merchants(m => m.GetMerchants([id, Guid.NewGuid()], CancellationToken.None));
        Assert.Equal([id], batch.Keys);
        using var scope = api.Services.CreateScope();
        var peers = scope.ServiceProvider.GetRequiredService<VerificationPeers>();
        Assert.Equal("Rahim Uddin", (await peers.Merchant(id, CancellationToken.None)).FullName);
        Assert.Equal([id], (await peers.MerchantsById([id], CancellationToken.None)).Keys);
        var missing = await Assert.ThrowsAsync<DomainException>(() => peers.Merchant(Guid.NewGuid(), CancellationToken.None));
        Assert.Equal(VerificationReasons.NotFound, missing.Reason);
        // Translated from Merchant's own answer, so the lazy "no Merchant area" fallback did not fire.
        Assert.Equal(MerchantErrors.NotFound, Assert.IsType<DomainException>(missing.InnerException).Reason);
    }

    [Fact]
    public async Task Validates_each_step()
    {
        var (_, token) = await api.SignIn("01712345679", "partner");
        var cases = new (string Step, object Body, string Code)[]
        {
            ("personal", new { fullName = "Rahim Uddin", dateOfBirth = "2015-01-01", gender = "male", presentAddress = "Banani 11", permanentAddress = "Cumilla Sadar" }, "AGE_REQUIREMENT"),
            ("personal", new { fullName = "Rahim Uddin", dateOfBirth = "1990-01-01", gender = "male", presentAddress = "     ", permanentAddress = "Cumilla Sadar" }, "VALIDATION_FAILED"),
            ("services", new { serviceIds = new[] { Guid.NewGuid() }, experienceYears = 1 }, "SERVICE_UNAVAILABLE"),
            ("area", new { homeBase = new { lat = 51.5, lng = 0 }, workingRadiusM = 5000 }, "VALIDATION_FAILED"),
            ("emergency-contact", new { name = "Me", relation = "Self", phone = "01712345679" }, "VALIDATION_FAILED"),
            ("emergency-contact", new { name = "Me", relation = "Self", phone = "01212345679" }, "VALIDATION_FAILED"),
            ("code-of-conduct", new { version = "2026-10", accepted = false }, "VALIDATION_FAILED"),
        };
        foreach (var (step, body, code) in cases)
        {
            Assert.Equal(code, PeopleApi.Code((await api.Call(HttpMethod.Put, $"/v1/provider/enrolment/{step}", token, body)).Body));
        }
        Assert.Equal("EMERGENCY_CONTACT_MISSING", PeopleApi.Code((await api.Call(HttpMethod.Post, Verify, token, new { code = "123456" })).Body));
        var contact = new { name = "Karim Uddin", relation = "Brother", phone = "01812345670" };
        await api.Call(HttpMethod.Put, "/v1/provider/enrolment/emergency-contact", token, contact);
        Assert.Equal("RATE_LIMITED", PeopleApi.Code((await api.Call(HttpMethod.Put, "/v1/provider/enrolment/emergency-contact", token, contact)).Body));
    }

    [Fact]
    public async Task Refuses_services_that_are_not_published()
    {
        var (_, token) = await api.SignIn("01712345680", "partner");
        var hidden = Guid.NewGuid();
        using (var scope = api.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<PaoDbContext>().Database.ExecuteSqlAsync($"""
                INSERT INTO catalog.services (id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
                    women_providers_only, requires_level_2, level2_checklist, sort_order, published, created_at, updated_at)
                SELECT {hidden}, category_id, 'Hidden', 'লুকানো', icon_key, service_model, 1, 5000, false, false, '[]'::jsonb, 99, false, now(), now()
                FROM catalog.services WHERE id = {Electrician}
                """);
        }
        var r = await api.Call(HttpMethod.Put, "/v1/provider/enrolment/services", token, new { serviceIds = new[] { Electrician, hidden }, experienceYears = 1 });
        Assert.Equal("SERVICE_UNAVAILABLE", PeopleApi.Code(r.Body));
    }

    [Fact]
    public async Task Sets_the_photo_and_language()
    {
        var (_, token) = await api.Enrol("01712345681", "male", Electrician);
        var photo = await api.Avatar(token, "provider");
        var r = await api.Call(HttpMethod.Put, "/v1/provider/profile", token, new { bio = "Licensed", language = "en", photoMediaId = photo });
        Assert.Equal(HttpStatusCode.OK, r.Status);
        Assert.Equal(("en", "none", 23.7937, 1), (r.Body.GetProperty("language").GetString(), r.Body.GetProperty("badge").GetString(),
            r.Body.GetProperty("homeBase").GetProperty("lat").GetDouble(), r.Body.GetProperty("services").GetArrayLength()));
        Assert.True(r.Body.TryGetProperty("photoUrl", out _));
        var unknown = await api.Call(HttpMethod.Put, "/v1/provider/profile", token, new { language = "bn", photoMediaId = Guid.NewGuid() });
        Assert.Equal("UPLOAD_INVALID", PeopleApi.Code(unknown.Body));
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await api.Call(HttpMethod.Put, "/v1/provider/profile", token, new { language = "bn", bio = new string('b', 600) })).Body));
        var (_, other) = await api.SignIn("01912345678", "partner");
        var fresh = await api.Call(HttpMethod.Get, "/v1/provider/profile", other);
        Assert.Equal((HttpStatusCode.OK, ""), (fresh.Status, fresh.Body.GetProperty("name").GetString()));
        Assert.False(fresh.Body.TryGetProperty("homeBase", out _));
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/provider/profile", other, new { language = "en" })).Status);
    }
}
