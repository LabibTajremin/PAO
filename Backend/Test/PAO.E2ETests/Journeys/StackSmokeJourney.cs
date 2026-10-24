using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Client;

namespace PAO.E2ETests.Journeys;

public sealed class StackSmokeJourney : Journey
{
    // The composition roots work in the image: the api and worker processes started and are
    // ready, and migrate migrated and seeded the database.
    [Fact]
    public async Task Smoke_services_start_and_are_ready()
    {
        var stack = Stack.Current;
        foreach (var (baseUrl, path) in new[] { (stack.Api, "/healthz"), (stack.Api, "/readyz"), (stack.Worker, "/healthz") })
        {
            var r = await Call(baseUrl, "GET", path);
            Assert.Equal((baseUrl + path, 200), (baseUrl + path, r.Status));
        }
        var c = await NewCustomer(PhoneFor("017", 71));
        var tree = (await Get("/v1/customer/catalog", c)).Expect(200);
        Assert.NotEmpty(Json.List(tree["categories"]));
        var electrician = await Providers.CatalogService(c, "Electrician");
        Assert.NotEmpty(electrician.Subs);
        Assert.True(electrician.Subs[0].Price > 0);
    }
}
