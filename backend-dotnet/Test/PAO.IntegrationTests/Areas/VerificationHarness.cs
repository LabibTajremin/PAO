using System.Net;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.EF;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Merchant;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

/// <summary>An API with the Verification area on a private database and fakes for the areas around it.</summary>
public abstract class VerificationHarness(MigratedDatabase database) : IAsyncLifetime
{
    protected VerificationMerchants Merchants { get; } = new();

    protected VerificationMedia Media { get; } = new();

    protected VerificationCatalog Catalog { get; } = new();

    protected FakeClock Clock { get; } = new(DateTimeOffset.UtcNow);

    protected AreaApi Api { get; private set; } = null!;

    // Signed per call: tokens are stamped with the fake clock, which tests move by days.
    protected string Verifier => Api.Token("verifier");

    public async ValueTask InitializeAsync()
    {
        Api = await AreaApi.Start(database.Url, services =>
        {
            services.AddSingleton<IMerchantSharedService>(Merchants);
            services.AddSingleton<IMediaSharedService>(Media);
            services.AddSingleton<ICatalogSharedService>(Catalog);
            services.AddSingleton<IAdminSharedService>(new VerificationSettingsFake());
            services.AddSingleton<IClock>(Clock);
        });
    }

    public async ValueTask DisposeAsync() => await Api.DisposeAsync();

    protected static string Date(DateTimeOffset at) => at.ToOffset(TimeSpan.FromHours(6)).ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);

    protected static string Code((HttpStatusCode Status, JsonElement Body) r) => r.Body.GetProperty("error").GetProperty("code").GetString()!;

    protected Task<(HttpStatusCode Status, JsonElement Body)> Put(string step, string token, object body) =>
        Api.Call(HttpMethod.Put, $"/v1/provider/enrolment/{step}", token, body);

    protected async Task Deliver(string name, object payload)
    {
        var bus = new EventBus();
        foreach (var subscriptions in Api.Services.GetServices<IEventSubscriptions>())
        {
            subscriptions.Subscribe(bus);
        }
        var envelope = new Envelope
        {
            Id = Guid.NewGuid(),
            Module = name.Split('.')[0],
            Name = name,
            AggregateId = "x",
            Payload = JsonSerializer.SerializeToElement(payload),
            OccurredAt = Clock.Now,
        };
        await bus.Dispatch(envelope, CancellationToken.None);
    }

    protected Task StepSaved(Guid id, string step) => Deliver(MerchantEvents.EnrolmentStepSaved, new { providerId = id, step });

    protected Task AccountStatus(Guid id, string to) => Deliver(IdentityEvents.AccountStatusChanged, new { accountId = id, to });

    protected async Task<T> Sql<T>(Func<PaoDbContext, Task<T>> query)
    {
        using var scope = Api.Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<PaoDbContext>());
    }

    protected Task<int> Count(string sql) => Sql(db => db.Database.SqlQueryRaw<int>(sql).SingleAsync());

    /// <summary>A merchant with every document step saved, the profile items pending and the enrolment submitted.</summary>
    protected async Task<(Guid Id, string Token)> Enrolled(Guid? service = null, string nid = "1712345678")
    {
        var id = Guid.NewGuid();
        var token = Api.Token(id, "provider");
        Merchants.Add(id, service ?? Catalog.Electrician);
        foreach (var step in new[] { "personal", "services", "area", "emergency_contact", "code_of_conduct" })
        {
            await StepSaved(id, step);
        }
        Assert.Equal(HttpStatusCode.OK, (await Put("nid", token, new { nidNumber = nid, frontMediaId = Media.Add(id, "nid_front"), backMediaId = Media.Add(id, "nid_back") })).Status);
        Assert.Equal(HttpStatusCode.OK, (await Put("selfie", token, new { mediaId = Media.Add(id, "selfie") })).Status);
        Assert.Equal(HttpStatusCode.OK, (await Put("police-clearance", token, new { mediaId = Media.Add(id, "police_clearance"), issueDate = Date(Clock.Now.AddDays(-30)) })).Status);
        Assert.Equal(HttpStatusCode.OK, (await Api.Call(HttpMethod.Post, "/v1/provider/enrolment/submit", token)).Status);
        return (id, token);
    }

    /// <summary>An enrolled merchant with every item approved: Level 1.</summary>
    protected async Task<(Guid Id, string Token)> Verified()
    {
        var p = await Enrolled();
        foreach (var item in new[] { "nid", "selfie", "police_clearance", "address", "emergency_contact", "service_area", "code_of_conduct" })
        {
            Assert.Equal(HttpStatusCode.OK, (await Api.Call(HttpMethod.Post, $"/v1/admin/verifications/{p.Id}/items/{item}/approve", Verifier)).Status);
        }
        return p;
    }
}
