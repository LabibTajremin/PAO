using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Providers;

namespace PAO.E2ETests.Journeys;

public sealed class OnboardingJourney : Journey
{
    [Fact]
    public async Task Onboarding_enrol_approve_go_online_and_be_found()
    {
        var c = await NewCustomer(PhoneFor("017", 1));
        var svc = await Service(c, "Electrician");
        var p = await EnrolledProvider(PhoneFor("018", 2), svc.Id, DateTimeOffset.UtcNow.AddMonths(-1));
        Assert.NotEqual(200, await TryOnline(p));

        await Approve(p, Items);
        var status = (await Get("/v1/provider/verification", p)).Expect(200);
        Json.Has(status, ("level", 1), ("canReceiveBookings", true));

        await GoOnline(p);
        await Eventually(Seconds(10), "provider in nearby search", () => Nearby(c, svc.Id, svc.Sub, p.Id!));
    }
}
