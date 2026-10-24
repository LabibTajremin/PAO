using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Providers;

namespace PAO.E2ETests.Journeys;

public sealed class BanJourney : Journey
{
    // Waits for the ban to reach identity (the worker relays it), then checks the old
    // access token is refused and the phone cannot ask for a login code.
    private static async Task ExpectLockedOut(Session s, string phone, string path)
    {
        await Eventually(Seconds(10), "session revoked", async () => (await Get(path, s)).Status == 401);
        await Eventually(Seconds(10), "sign-in refused", async () =>
        {
            var r = await RequestCode(phone);
            if (r.Status == 202)
            {
                throw new InvalidOperationException("a banned phone was sent a login code");
            }
            return r.Status == 403 && r.Code() == "ACCOUNT_BANNED";
        });
    }

    [Fact]
    public async Task Ban_provider_loses_sessions_search_and_sign_in()
    {
        var c = await NewCustomer(PhoneFor("017", 41));
        var svc = await Service(c, "Electrician");
        var p = await Bookings.OnlineProvider(42, svc.Id);
        await Eventually(Seconds(10), "provider in nearby search", () => Nearby(c, svc.Id, svc.Sub, p.Id));

        var root = await Admins.Admin("super@pao.bd");
        var ban = new { status = "banned", reason = "Fraudulent documents" };
        var banned = (await Send("POST", $"/v1/admin/providers/{p.Id}/status", ban, root)).Expect(200);
        Assert.Equal("banned", Json.Str(Json.Obj(banned["summary"])["status"]));

        await ExpectLockedOut(p.Session, p.Phone, "/v1/provider/profile");
        await Eventually(Seconds(10), "banned provider hidden from search", async () => !await Nearby(c, svc.Id, svc.Sub, p.Id));
    }

    [Fact]
    public async Task Ban_customer_loses_sessions_and_sign_in()
    {
        var phone = PhoneFor("017", 43);
        var c = await NewCustomer(phone);
        (await Get("/v1/customer/profile", c)).Expect(200);
        var root = await Admins.Admin("super@pao.bd");
        var path = $"/v1/admin/customers/{c.Id}/status";

        Assert.Equal(422, (await Send("POST", path, new { status = "banned" }, root)).Status);
        (await Send("POST", path, new { status = "banned", reason = "Abused providers" }, root)).Expect(200);
        await ExpectLockedOut(c, phone, "/v1/customer/profile");
    }
}
