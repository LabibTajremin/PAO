using System.Net;
using System.Text.Json;
using PAO.Core.Areas.Billing.Services.Shared;
using PAO.Lib.Areas.Billing;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

/// <summary>Cash on delivery and merchant dues end to end (ADR-0035), every area real.</summary>
public sealed class BillingApiTests : IAsyncLifetime
{
    private const string Summary = "/v1/provider/billing/summary";
    private const string Payments = "/v1/provider/billing/payments";
    private PeopleApi api = null!;

    private string url = string.Empty;

    // Each test gets its own database: the totals it checks are its own.
    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(url = await TestDatabases.CreateMigrated());

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private static string? Code((HttpStatusCode, JsonElement Body) r) => PeopleApi.Code(r.Body);

    private static long Long(JsonElement e, string name) => e.GetProperty(name).GetInt64();

    [Fact]
    public async Task Charges_ten_percent_on_completion_once_and_blocks_accepting_above_the_limit()
    {
        await api.SetSetting("billing.due_block_amount", "5000");
        var w = await Create(api);
        var id = await w.Completed("bill-1");
        await w.Relay();
        var due = (await w.AsProvider(HttpMethod.Get, Summary)).Body;
        // Two fans at ৳500: ৳1000, 10% is ৳100.
        Assert.Equal((10_000L, 5_000L, true, 1000, 0L), (Long(due, "due"), Long(due, "blockAmount"), due.GetProperty("blocked").GetBoolean(),
            due.GetProperty("commissionRateBp").GetInt32(), Long(due, "pendingPayments")));
        await api.Deliver("booking.BookingCompleted", new { bookingId = id, providerId = w.Provider.Id, number = "PAO-1", totalPaisa = 100_000 }, api.Bus(true));
        var ledger = (await w.AsProvider(HttpMethod.Get, "/v1/provider/billing/ledger")).Body.GetProperty("items");
        Assert.Equal(1, ledger.GetArrayLength());
        Assert.Equal(("commission", 10_000L, 100_000L, id.ToString()), (ledger[0].GetProperty("kind").GetString(), Long(ledger[0], "amount"),
            Long(ledger[0], "jobTotal"), ledger[0].GetProperty("bookingId").GetString()));
        Assert.StartsWith("PAO-", ledger[0].GetProperty("bookingNumber").GetString());
        var next = await w.Book("bill-2");
        var refused = await w.Job(next, "accept");
        Assert.Equal((HttpStatusCode.Conflict, "MERCHANT_DUE_LIMIT"), (refused.Status, Code(refused)));
        var status = await w.Contract<IBillingSharedService, DueStatus>(b => b.GetDueStatus(w.Provider.Id, CancellationToken.None));
        Assert.True(status.Blocked);
        Assert.Equal("cash_on_delivery", (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}")).Body.GetProperty("paymentMethod").GetString());
        Assert.Equal("cash_on_delivery", (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}/receipt")).Body.GetProperty("paymentMethod").GetString());
        await w.Relay();
        var inbox = (await w.AsProvider(HttpMethod.Get, "/v1/provider/notifications")).Body.GetProperty("items").ToString();
        Assert.Contains("৳100", inbox, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Takes_payments_that_admins_confirm_or_reject_with_a_reason_lifting_the_block()
    {
        await api.SetSetting("billing.due_block_amount", "5000");
        var w = await Create(api);
        await w.Completed("pay-1");
        await w.Relay();
        var admin = api.Api.Token(Guid.NewGuid(), "super_admin");
        var first = await w.AsProvider(HttpMethod.Post, Payments, new { amountPaisa = 6000, method = "bkash", reference = " TX-1 " });
        Assert.Equal((HttpStatusCode.Created, "pending", "TX-1"), (first.Status, first.Body.GetProperty("status").GetString(), first.Body.GetProperty("reference").GetString()));
        Assert.Equal(6000L, Long((await w.AsProvider(HttpMethod.Get, Summary)).Body, "pendingPayments"));
        Assert.Equal("VALIDATION_FAILED", Code(await w.AsProvider(HttpMethod.Post, Payments, new { amountPaisa = 6000, method = "cheque", reference = "x" })));
        var queue = (await api.Call(HttpMethod.Get, "/v1/admin/billing/payments?status=pending", admin)).Body.GetProperty("items");
        Assert.Equal(1, queue.GetArrayLength());
        var sid = first.Body.GetProperty("id").GetString();
        Assert.Equal("VALIDATION_FAILED", Code(await api.Call(HttpMethod.Post, $"/v1/admin/billing/payments/{sid}/reject", admin, new { reason = "  " })));
        var rejected = await api.Call(HttpMethod.Post, $"/v1/admin/billing/payments/{sid}/reject", admin, new { reason = "No such bKash transaction" });
        Assert.Equal(("rejected", "No such bKash transaction"), (rejected.Body.GetProperty("status").GetString(), rejected.Body.GetProperty("reason").GetString()));
        Assert.Equal("PAYMENT_NOT_PENDING", Code(await api.Call(HttpMethod.Post, $"/v1/admin/billing/payments/{sid}/confirm", admin)));
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"/v1/admin/billing/payments/{Guid.NewGuid()}/confirm", admin)).Status);
        var second = await w.AsProvider(HttpMethod.Post, Payments, new { amountPaisa = 6000, method = "cash_to_agent", reference = "Agent Karim" });
        var confirmed = await api.Call(HttpMethod.Post, $"/v1/admin/billing/payments/{second.Body.GetProperty("id").GetString()}/confirm", admin);
        Assert.Equal(("confirmed", true), (confirmed.Body.GetProperty("status").GetString(), confirmed.Body.TryGetProperty("reviewedAt", out _)));
        var due = (await w.AsProvider(HttpMethod.Get, Summary)).Body;
        Assert.Equal((4000L, false, 0L), (Long(due, "due"), due.GetProperty("blocked").GetBoolean(), Long(due, "pendingPayments")));
        Assert.Equal(HttpStatusCode.OK, (await w.Job(await w.Book("pay-2"), "accept")).Status);
        await AssertPagesAndViews(w, admin);
    }

    private async Task AssertPagesAndViews(BookingWorld w, string admin)
    {
        var mine = await w.AsProvider(HttpMethod.Get, Payments + "?limit=1");
        Assert.Equal(1, mine.Body.GetProperty("items").GetArrayLength());
        var rest = await w.AsProvider(HttpMethod.Get, $"{Payments}?limit=1&cursor={mine.Body.GetProperty("nextCursor").GetString()}");
        Assert.False(rest.Body.TryGetProperty("nextCursor", out _));
        Assert.Equal("rejected", rest.Body.GetProperty("items")[0].GetProperty("status").GetString());
        var view = (await api.Call(HttpMethod.Get, $"/v1/admin/billing/merchants/{w.Provider.Id}/ledger?limit=1", admin)).Body;
        Assert.Equal((4000L, 1), (Long(view.GetProperty("summary"), "due"), view.GetProperty("entries").GetProperty("items").GetArrayLength()));
        var older = await api.Call(HttpMethod.Get,
            $"/v1/admin/billing/merchants/{w.Provider.Id}/ledger?cursor={view.GetProperty("entries").GetProperty("nextCursor").GetString()}", admin);
        Assert.Equal("commission", older.Body.GetProperty("entries").GetProperty("items")[0].GetProperty("kind").GetString());
        Assert.Equal(HttpStatusCode.Forbidden, (await api.Call(HttpMethod.Get, "/v1/admin/billing/payments", w.Provider.Token)).Status);
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Get, "/v1/admin/billing/payments", api.Api.Token("support_agent"))).Status);
        await w.Relay();
        var audit = (await api.Call(HttpMethod.Get, "/v1/admin/audit", admin)).Body.ToString();
        Assert.Contains("billing.payment_rejected", audit, StringComparison.Ordinal);
        Assert.Contains("billing.payment_confirmed", audit, StringComparison.Ordinal);
        var inbox = (await w.AsProvider(HttpMethod.Get, "/v1/provider/notifications?limit=100")).Body.GetProperty("items").ToString();
        Assert.Contains("No such bKash transaction", inbox, StringComparison.Ordinal);
    }
}
