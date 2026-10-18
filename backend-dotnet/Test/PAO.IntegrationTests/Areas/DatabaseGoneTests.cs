using System.Net;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

public sealed class DatabaseGoneTests : IAsyncLifetime
{
    private string url = string.Empty;
    private AreaApi api = null!;

    public async ValueTask InitializeAsync()
    {
        url = await TestDatabases.CreateMigrated();
        api = await AreaApi.Start(url, services => services.AddSingleton<IAuditSharedService>(new FakeAudit()));
    }

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    [Fact]
    public async Task Catalog_media_and_notification_answer_500_after_checking_the_rules()
    {
        var customer = api.Token("customer");
        var admin = api.Token("catalog_manager");
        var both = api.Token("provider", "customer");
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Get, "/v1/customer/catalog", customer)).Status);
        await TestDatabases.Drop(url);
        var id = Guid.NewGuid();
        var category = new { name = new { en = "A", bn = "B" }, iconKey = "x" };
        var device = new { token = "device-token-closed", platform = "web" };
        var calls = new (HttpMethod Method, string Path, string Token, object? Body)[]
        {
            (HttpMethod.Get, "/v1/customer/catalog", customer, null),
            (HttpMethod.Get, "/v1/provider/catalog", customer, null),
            (HttpMethod.Get, "/v1/admin/catalog", admin, null),
            (HttpMethod.Get, "/v1/customer/catalog/search?q=fan", customer, null),
            (HttpMethod.Get, $"/v1/customer/services/{id}", customer, null),
            (HttpMethod.Post, "/v1/admin/catalog/categories", admin, category),
            (HttpMethod.Put, $"/v1/admin/catalog/categories/{id}", admin, category),
            (HttpMethod.Get, $"/v1/admin/catalog/sub-services/{id}/prices", admin, null),
            (HttpMethod.Post, "/v1/provider/uploads", both, new { purpose = "avatar", contentType = "image/jpeg", sizeBytes = 10 }),
            (HttpMethod.Post, $"/v1/provider/uploads/{id}/confirm", both, null),
            (HttpMethod.Get, "/v1/provider/notifications", both, null),
            (HttpMethod.Get, "/v1/customer/notifications", both, null),
            (HttpMethod.Post, "/v1/customer/notifications/read-all", both, null),
            (HttpMethod.Post, $"/v1/customer/notifications/{id}/read", both, null),
            (HttpMethod.Put, "/v1/customer/device-token", both, device),
        };
        foreach (var (method, path, token, body) in calls)
        {
            Assert.Equal((method, path, HttpStatusCode.InternalServerError), (method, path, (await api.Call(method, path, token, body)).Status));
        }
        var invalid = await api.Call(HttpMethod.Post, "/v1/customer/uploads", customer, new { purpose = "nid_front", contentType = "image/jpeg", sizeBytes = 10 });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, invalid.Status);
    }
}
