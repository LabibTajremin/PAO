using System.Text.Json.Nodes;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Verification;

namespace PAO.Core.Areas.Audit.Services;

/// <summary>
/// Turns each audited event into its entry. Every event that changes a person's status, a
/// price or a decision is audited (02-architecture §8); verification decisions record who,
/// when, what and why (PRD §6.4).
/// </summary>
public static class EventEntries
{
    private const string Verifier = "verifier";

    /// <summary>The audited event names and their maps; a payload missing its subject fails the record.</summary>
    public static readonly IReadOnlyDictionary<string, Func<EventPayload, AuditEntry>> Maps = new Dictionary<string, Func<EventPayload, AuditEntry>>
    {
        [IdentityEvents.AccountStatusChanged] = p => Entry(p, "account.status_changed", "account", Subject(p, "accountId"), reason: p.Text("reason"),
            before: new JsonObject { ["status"] = p.Text("from") }, after: new JsonObject { ["status"] = p.Text("to") }),
        [CatalogEvents.PriceChanged] = p => Entry(p, "catalog.price_changed", "sub_service", Subject(p, "subServiceId"),
            after: new JsonObject { ["amountPaisa"] = p.Number("amountPaisa"), ["priceVersionId"] = p.Id("priceVersionId") }),
        [AdminEvents.SettingChanged] = p => Entry(p, "settings.changed", "setting", p.Text("key"),
            before: new JsonObject { ["value"] = p.Text("before") }, after: new JsonObject { ["value"] = p.Text("after") }),
        [AdminEvents.ComplaintResolved] = p => Entry(p, "complaint.resolved", "complaint", Subject(p, "complaintId"),
            after: new JsonObject { ["ticket"] = p.Text("ticketNumber"), ["verified"] = p.Flag("verified"), ["againstId"] = p.Id("againstId") }),
        [VerificationEvents.DocumentApproved] = p => Entry(p, "verification.item_approved", "provider", Subject(p, "providerId"), Verifier,
            after: new JsonObject { ["item"] = p.Text("item"), ["status"] = "approved" }),
        [VerificationEvents.DocumentRejected] = p => Entry(p, "verification.item_rejected", "provider", Subject(p, "providerId"), Verifier, p.Text("reason"),
            after: new JsonObject { ["item"] = p.Text("item"), ["status"] = "rejected" }),
        [VerificationEvents.ProviderLevelChanged] = p => Entry(p, "verification.level_changed", "provider", Subject(p, "providerId"), reason: p.Text("reason"),
            before: new JsonObject { ["level"] = p.Number("from") }, after: new JsonObject { ["level"] = p.Number("to") }),
        [VerificationEvents.Level2ResultRecorded] = p => Entry(p, "verification.level2_result", "provider", Subject(p, "providerId"), Verifier,
            after: new JsonObject { ["session"] = p.Id("sessionId"), ["result"] = p.Text("result") }),
        [BillingEvents.CommissionCharged] = p => Entry(p, "billing.commission_charged", "provider", Subject(p, "providerId"),
            after: new JsonObject { ["bookingId"] = p.Id("bookingId"), ["amountPaisa"] = p.Number("amountPaisa"), ["duePaisa"] = p.Number("duePaisa") }),
        [BillingEvents.PaymentSubmitted] = p => Payment(p, "billing.payment_submitted", "provider"),
        [BillingEvents.PaymentConfirmed] = p => Payment(p, "billing.payment_confirmed", "admin"),
        [BillingEvents.PaymentRejected] = p => Payment(p, "billing.payment_rejected", "admin"),
        [VerificationEvents.DocumentExpired] = p => Entry(p, "verification.item_expired", "provider", Subject(p, "providerId"),
            after: new JsonObject { ["item"] = p.Text("item"), ["status"] = "expired" }),
    };

    // A missing id reads as the nil UUID; as a subject it counts as absent.
    private static string Subject(EventPayload p, string name) => p.Id(name) is var id && id == UuidText.Nil ? string.Empty : id;

    private static AuditEntry Payment(EventPayload p, string action, string actorRole) =>
        Entry(p, action, "payment_submission", Subject(p, "submissionId"), actorRole, p.Text("reason"), after: new JsonObject
        {
            ["providerId"] = p.Id("providerId"),
            ["amountPaisa"] = p.Number("amountPaisa"),
            ["method"] = p.Text("method"),
            ["duePaisa"] = p.Number("duePaisa"),
        });

    private static AuditEntry Entry(
        EventPayload p, string action, string subjectType, string subjectId, string actorRole = "", string reason = "",
        JsonObject? before = null, JsonObject? after = null)
    {
        var actor = p.Id("actorId");
        return new AuditEntry
        {
            Id = Guid.Empty,
            At = default,
            ActorId = actor == UuidText.Nil ? null : Guid.Parse(actor),
            ActorRole = actorRole,
            Action = action,
            SubjectType = subjectType,
            SubjectId = subjectId,
            Reason = reason,
            Before = before,
            After = after,
        };
    }
}
