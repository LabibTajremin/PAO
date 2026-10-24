using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Client;

namespace PAO.E2ETests.Journeys;

public sealed class RbacJourney : Journey
{
    // Seeded admins and the role each holds (docs/build/02-architecture.md §6).
    private const string Root = "super@pao.bd";
    private const string Verifier = "verifier@pao.bd";
    private const string Catalog = "catalog@pao.bd";
    private const string Support = "support@pao.bd";
    private const string Missing = "00000000-0000-4000-8000-000000000000";

    private sealed record Probe(string Permission, string Method, string Path, object? Body, int PermittedCode, string[] Roles);

    // One representative endpoint per admin permission. Probes that would change something
    // name an ID or key that does not exist, so a permitted call stops at 404 after the
    // permission check and a forbidden one at 403 before it.
    private static readonly Probe[] Probes =
    [
        new("dashboard:read", "GET", "/v1/admin/dashboard", null, 200, [Root, Verifier, Catalog, Support]),
        new("catalog:manage", "GET", "/v1/admin/catalog", null, 200, [Root, Catalog]),
        new("settings:read", "GET", "/v1/admin/settings", null, 200, [Root, Catalog]),
        new("settings:manage", "PUT", "/v1/admin/settings/no.such.setting", new { value = "1" }, 404, [Root]),
        new("verification:review", "GET", "/v1/admin/verifications", null, 200, [Root, Verifier]),
        new("verification:docs:view", "GET", $"/v1/admin/documents/{Missing}/view-url", null, 404, [Root, Verifier]),
        new("level2:manage", "GET", "/v1/admin/level2-sessions", null, 200, [Root, Verifier]),
        new("provider:read", "GET", "/v1/admin/providers", null, 200, [Root, Verifier, Support]),
        new("provider:manage", "POST", $"/v1/admin/providers/{Missing}/status", new { status = "suspended", reason = "RBAC probe" }, 404, [Root]),
        new("customer:read", "GET", "/v1/admin/customers", null, 200, [Root, Support]),
        new("customer:manage", "POST", $"/v1/admin/customers/{Missing}/status", new { status = "suspended", reason = "RBAC probe" }, 404, [Root]),
        new("booking:read:any", "GET", "/v1/admin/bookings", null, 200, [Root, Support]),
        new("complaint:manage", "GET", "/v1/admin/complaints", null, 200, [Root, Support]),
        new("audit:read", "GET", "/v1/admin/audit", null, 200, [Root]),
        new("admin_user:manage", "GET", "/v1/admin/admin-users", null, 200, [Root]),
        new("role:manage", "GET", "/v1/admin/roles", null, 200, [Root]),
    ];

    [Fact]
    public async Task Rbac_each_admin_role_reaches_only_its_endpoints()
    {
        var mismatches = new List<string>();
        foreach (var email in new[] { Root, Verifier, Catalog, Support })
        {
            var s = await Admins.Admin(email);
            foreach (var probe in Probes)
            {
                var want = probe.Roles.Contains(email) ? probe.PermittedCode : 403;
                var r = await Send(probe.Method, probe.Path, probe.Body, s);
                if (r.Status != want)
                {
                    mismatches.Add($"{email} {probe.Method} {probe.Path} ({probe.Permission}): want {want}, got {r.Status} {r.Body}");
                }
                if (want == 403 && r.Code() != "FORBIDDEN")
                {
                    mismatches.Add($"{email} {probe.Path}: error code \"{r.Code()}\"");
                }
            }
        }
        Assert.Empty(mismatches);
    }

    [Fact]
    public async Task Rbac_app_users_cannot_reach_the_admin_api()
    {
        var c = await NewCustomer(PhoneFor("017", 51));
        var mismatches = new List<string>();
        foreach (var probe in Probes)
        {
            var r = await Send(probe.Method, probe.Path, probe.Body, c);
            if (r.Status != 403)
            {
                mismatches.Add($"customer {probe.Method} {probe.Path}: {r.Status}");
            }
        }
        var anonymous = await Get("/v1/admin/dashboard");
        if (anonymous.Status != 401)
        {
            mismatches.Add($"anonymous dashboard: {anonymous.Status}");
        }
        Assert.Empty(mismatches);
    }
}
