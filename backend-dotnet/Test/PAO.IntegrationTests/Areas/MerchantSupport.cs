using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Lib.Areas.Catalog;

namespace PAO.IntegrationTests.Areas;

/// <summary>Enrolment and presence steps the Merchant tests repeat.</summary>
public static class MerchantSteps
{
    public static readonly Guid Electrician = SeedIds.For("service", "electrician");
    public static readonly Guid HomeSalon = SeedIds.For("service", "home-salon");
    public static readonly object Near = new { location = new { lat = 23.7937, lng = 90.4066 } };

    public static object Personal(string gender) => new
    {
        fullName = "Rahim Uddin", dateOfBirth = "1990-04-12", gender, presentAddress = "Banani 11", permanentAddress = "Cumilla Sadar",
    };

    /// <summary>Signs in on the partner app and saves the personal, services and area steps.</summary>
    public static async Task<(Guid Id, string Token)> Enrol(this PeopleApi api, string phone, string gender, params Guid[] services)
    {
        var (id, token) = await api.SignIn(phone, "partner");
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/provider/enrolment/personal", token, Personal(gender))).Status);
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/provider/enrolment/services", token, new { serviceIds = services, experienceYears = 8 })).Status);
        var area = new { homeBase = new { lat = 23.7937, lng = 90.4066 }, workingRadiusM = 8000 };
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/provider/enrolment/area", token, area)).Status);
        return (id, token);
    }

    /// <summary>Enrols, raises the level through Verification's event and goes online near Banani.</summary>
    public static async Task<(Guid Id, string Token)> Online(this PeopleApi api, string phone, string gender, int level, params Guid[] services)
    {
        var (id, token) = await api.Enrol(phone, gender, services);
        await api.Deliver("verification.ProviderLevelChanged", new { providerId = id, from = 0, to = level });
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Post, "/v1/provider/presence/online", token, Near)).Status);
        return (id, token);
    }

    /// <summary>Runs `call` against the Merchant contract in its own scope.</summary>
    public static async Task<T> Merchants<T>(this PeopleApi api, Func<IMerchantSharedService, Task<T>> call)
    {
        using var scope = api.Services.CreateScope();
        return await call(scope.ServiceProvider.GetRequiredService<IMerchantSharedService>());
    }

    public static Dictionary<string, bool> Done(JsonElement status) =>
        status.GetProperty("steps").EnumerateArray().ToDictionary(s => s.GetProperty("step").GetString()!, s => s.GetProperty("done").GetBoolean());
}
