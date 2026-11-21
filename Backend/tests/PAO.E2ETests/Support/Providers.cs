using System.Globalization;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Json;

namespace PAO.E2ETests.Support;

/// <summary>A sub-service with its current price in paisa.</summary>
public sealed record Sub(string Id, long Price);

/// <summary>A seeded service with its sub-services in catalog order.</summary>
public sealed record Offer(string Id, IReadOnlyList<Sub> Subs)
{
    /// <summary>The first sub-service.</summary>
    public Sub First => Subs.Count > 0 ? Subs[0] : throw new InvalidOperationException($"service {Id} has no sub-services");
}

/// <summary>Provider enrolment, verification, presence and nearby search.</summary>
public static class Providers
{
    /// <summary>Where every e2e provider works and every e2e customer lives.</summary>
    public static readonly (double Lat, double Lng) Banani = (23.7937, 90.4066);

    /// <summary>The Level 1 verification items a verifier approves.</summary>
    public static readonly string[] Items = ["nid", "selfie", "police_clearance", "address", "emergency_contact", "service_area", "code_of_conduct"];

    private static object BananiJson => new { lat = Banani.Lat, lng = Banani.Lng };

    /// <summary>Finds a seeded service by English name in the customer catalog.</summary>
    public static async Task<Offer> CatalogService(Session s, string name)
    {
        var tree = (await Get("/v1/customer/catalog", s)).Expect(200);
        foreach (var category in List(tree["categories"]))
        {
            var found = List(category["services"]).FirstOrDefault(svc => Str(Obj(svc["name"])["en"]) == name);
            if (found is not null)
            {
                return new Offer(Str(found["id"]), List(found["subServices"]).Select(it => new Sub(Str(it["id"]), Num(it["price"]))).ToList());
            }
        }
        throw new InvalidOperationException($"no service \"{name}\"");
    }

    /// <summary>A seeded service's ID and the ID of its first sub-service.</summary>
    public static async Task<(string Id, string Sub)> Service(Session s, string name)
    {
        var offer = await CatalogService(s, name);
        return (offer.Id, offer.First.Id);
    }

    /// <summary>A calendar date as the API takes it, YYYY-MM-DD.</summary>
    public static string DateOnlyOf(DateTimeOffset at) => at.UtcDateTime.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    private static async Task<(string Step, object Body)[]> EnrolmentSteps(Session p, string phone, string serviceId, DateTimeOffset policeIssued)
    {
        var contact = "019" + phone[^8..];
        return
        [
            ("personal", new { fullName = "Rahim Uddin", dateOfBirth = "1990-04-12", gender = "male", presentAddress = "House 12, Banani", permanentAddress = "Cumilla Sadar" }),
            ("services", new { serviceIds = new[] { serviceId }, experienceYears = 8 }),
            ("area", new { homeBase = BananiJson, workingRadiusM = 8000 }),
            ("code-of-conduct", new { version = "2026-10", accepted = true }),
            ("emergency-contact", new { name = "Karim Uddin", relation = "Brother", phone = contact }),
            ("nid", new { nidNumber = "1" + phone[^9..], frontMediaId = await Upload(p, "provider", "nid_front"), backMediaId = await Upload(p, "provider", "nid_back") }),
            ("selfie", new { mediaId = await Upload(p, "provider", "selfie") }),
            ("police-clearance", new { mediaId = await Upload(p, "provider", "police_clearance"), issueDate = DateOnlyOf(policeIssued) }),
        ];
    }

    /// <summary>
    /// Signs a partner-app user in, completes every enrolment step with documents and
    /// submits it; `policeIssued` dates the police clearance.
    /// </summary>
    public static async Task<Session> EnrolledProvider(string phone, string serviceId, DateTimeOffset policeIssued)
    {
        var p = await SignIn(phone, "partner");
        foreach (var (step, body) in await EnrolmentSteps(p, phone, serviceId, policeIssued))
        {
            (await Send("PUT", $"/v1/provider/enrolment/{step}", body, p)).Expect(200);
        }
        var code = await LastCode("019" + phone[^8..]);
        (await Send("POST", "/v1/provider/enrolment/emergency-contact/verify", new { code }, p)).Expect(200);
        (await Send("POST", "/v1/provider/enrolment/submit", null, p)).Expect(200);
        return p;
    }

    /// <summary>
    /// Has the seeded verifier approve each item of `p`'s submission, once the worker has
    /// relayed the submission and every item waits for review.
    /// </summary>
    public static async Task Approve(Session p, params string[] which)
    {
        var v = await Admins.Admin("verifier@pao.bd");
        await Eventually(Seconds(10), "items pending review", async () =>
        {
            var status = (await Get($"/v1/admin/verifications/{p.Id}", v)).Expect(200);
            var pending = List(status["items"]).Where(it => Str(it["status"]) == "pending").Select(it => Str(it["type"])).ToHashSet();
            return which.All(pending.Contains);
        });
        foreach (var item in which)
        {
            var path = $"/v1/admin/verifications/{p.Id}/items/{item}/approve";
            // One verifier approves every provider of the suite; back-to-back runs can pass the
            // per-user limit of 120 calls a minute, so wait for the window to slide.
            await Eventually(Seconds(70), "approval within the rate limit", async () =>
            {
                var r = await Send("POST", path, null, v);
                if (r.Status != 200 && r.Status != 429)
                {
                    throw new InvalidOperationException($"POST {path}: {r.Status} {r.Body}");
                }
                return r.Status == 200;
            });
        }
    }

    /// <summary>Brings `p` online in Banani; the status of the call is returned, not checked.</summary>
    public static async Task<int> TryOnline(Session p) =>
        (await Send("POST", "/v1/provider/presence/online", new { location = BananiJson }, p)).Status;

    /// <summary>Waits for the approved level to reach the provider module, then goes online.</summary>
    public static Task GoOnline(Session p) =>
        Eventually(Seconds(10), "provider allowed online", async () => await TryOnline(p) == 200);

    /// <summary>
    /// Whether customer `c` finds provider `providerId` for the sub-service, reading every
    /// page: providers of earlier runs may still be online at the same spot.
    /// </summary>
    public static async Task<bool> Nearby(Session c, string serviceId, string subServiceId, string providerId)
    {
        var q = string.Create(CultureInfo.InvariantCulture, $"/v1/customer/providers/nearby?serviceId={serviceId}&subServiceId={subServiceId}&quantity=1&lat={Banani.Lat}&lng={Banani.Lng}");
        for (var page = q; ;)
        {
            var res = (await Get(page, c)).Expect(200);
            if (List(res["items"]).Any(it => Str(it["id"]) == providerId))
            {
                return true;
            }
            var next = res["nextCursor"] is { } n && n.GetValueKind() == System.Text.Json.JsonValueKind.String ? Str(n) : string.Empty;
            if (next.Length == 0)
            {
                return false;
            }
            page = $"{q}&cursor={Uri.EscapeDataString(next)}";
        }
    }
}
