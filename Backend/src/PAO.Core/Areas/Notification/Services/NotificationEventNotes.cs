using System.Globalization;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Areas.Verification;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>One recipient of a booking event.</summary>
public sealed record Note(string To, string App, string Template, IReadOnlyDictionary<string, string>? Extra = null);

/// <summary>Turns other areas' events into notifications; dedupe keys make redelivery harmless.</summary>
public sealed class NotificationEventNotes(NotificationSender sender, NotificationPeers peers, ILogger<NotificationEventNotes> logger)
{
    private static readonly Dictionary<string, (string En, string Bn)> Items = new(StringComparer.Ordinal)
    {
        ["nid"] = ("NID", "এনআইডি"),
        ["selfie"] = ("selfie", "সেলফি"),
        ["police_clearance"] = ("police clearance", "পুলিশ ক্লিয়ারেন্স"),
        ["address"] = ("address", "ঠিকানা"),
        ["emergency_contact"] = ("emergency contact", "জরুরি যোগাযোগ"),
        ["skill_proof"] = ("skill proof", "দক্ষতার প্রমাণ"),
        ["service_area"] = ("service area", "সেবা এলাকা"),
        ["code_of_conduct"] = ("code of conduct", "আচরণবিধি"),
    };

    private static readonly Dictionary<string, (string Template, Func<EventPayload, string, Dictionary<string, string>> Data)> VerificationNotes = new(StringComparer.Ordinal)
    {
        [VerificationEvents.ProviderLevelChanged] = ("level_changed", (p, _) => new() { ["level"] = Number(p.Number("to")) }),
        [VerificationEvents.DocumentRejected] = ("document_rejected", (p, l) => new() { ["item"] = ItemName(p.Text("item"), l), ["reason"] = p.Text("reason") }),
        [VerificationEvents.DocumentExpired] = ("document_expired", (p, l) => new() { ["item"] = ItemName(p.Text("item"), l) }),
        [VerificationEvents.DocumentExpiring] = ("document_expiring", (p, l) => new() { ["item"] = ItemName(p.Text("item"), l), ["days"] = Number(p.Number("daysLeft")) }),
        [VerificationEvents.Level2SessionScheduled] = ("level2_scheduled", (p, _) => new() { ["location"] = p.Text("location"), ["when"] = p.Text("scheduledAt") }),
    };

    /// <summary>Every event name that notifies someone.</summary>
    public static IEnumerable<string> EventNames =>
        [AdminEvents.ComplaintResolved, .. VerificationNotes.Keys, .. BillingNotes.Notes.Keys, .. BookingNotes.Recipients.Keys];

    /// <summary>Notifies whoever `envelope` concerns.</summary>
    public Task Handle(Envelope envelope, CancellationToken cancellationToken)
    {
        var p = new EventPayload(envelope);
        if (envelope.Name == AdminEvents.ComplaintResolved)
        {
            return ComplaintResolved(envelope, p, cancellationToken);
        }
        if (VerificationNotes.TryGetValue(envelope.Name, out var note))
        {
            return ToProvider(envelope, p, note.Template, note.Data, cancellationToken);
        }
        if (BillingNotes.Notes.TryGetValue(envelope.Name, out var billing))
        {
            var (template, data) = billing(p);
            return ToProvider(envelope, p, template, (_, _) => data, cancellationToken);
        }
        return OnBooking(envelope, p, BookingNotes.Recipients[envelope.Name](p), cancellationToken);
    }

    private async Task ToProvider(Envelope envelope, EventPayload p, string template, Func<EventPayload, string, Dictionary<string, string>> data, CancellationToken cancellationToken)
    {
        var recipient = Guid.Parse(p.Id("providerId"));
        var language = await peers.Language(recipient, NotificationApp.Partner, cancellationToken);
        await sender.Send(new Outgoing(recipient, NotificationApp.Partner, template, data(p, language), null, envelope.Id.ToString(), language), cancellationToken);
    }

    private async Task ComplaintResolved(Envelope envelope, EventPayload p, CancellationToken cancellationToken)
    {
        var recipient = Guid.Parse(p.Id("reporterId"));
        var app = p.Text("reporterRole") switch
        {
            "customer" => NotificationApp.Customer,
            "provider" => NotificationApp.Partner,
            _ => string.Empty,
        };
        var language = app.Length == 0 ? "bn" : await peers.Language(recipient, app, cancellationToken);
        var data = new Dictionary<string, string> { ["ticket"] = p.Text("ticketNumber") };
        await sender.Send(new Outgoing(recipient, app, "complaint_resolved", data, null, envelope.Id.ToString(), language), cancellationToken);
    }

    private async Task OnBooking(Envelope envelope, EventPayload p, IReadOnlyList<Note> notes, CancellationToken cancellationToken)
    {
        var bookingId = Guid.Parse(p.Id("bookingId"));
        var b = await peers.Booking(bookingId, cancellationToken);
        if (b is null)
        {
            // Retrying cannot make a missing booking appear, so the event is dropped rather
            // than blocking the outbox.
            logger.LogWarning("notification for unknown booking {Booking} {Event}", bookingId, envelope.Name);
            return;
        }
        foreach (var n in notes)
        {
            var language = await peers.Language(Guid.Parse(n.To), n.App, cancellationToken);
            var data = new Dictionary<string, string>
            {
                ["number"] = b.Number,
                ["service"] = language == "en" ? b.ServiceEn : b.ServiceBn,
                ["area"] = b.Area,
                ["provider"] = b.ProviderName,
                ["customer"] = b.CustomerName,
            };
            foreach (var (key, value) in n.Extra ?? new Dictionary<string, string>())
            {
                data[key] = value;
            }
            await sender.Send(new Outgoing(Guid.Parse(n.To), n.App, n.Template, data, bookingId, $"{envelope.Id}:{n.Template}", language), cancellationToken);
        }
    }

    private static string ItemName(string item, string language) =>
        Items.TryGetValue(item, out var names) ? (language == "en" ? names.En : names.Bn) : string.Empty;

    private static string Number(double value) => value.ToString(CultureInfo.InvariantCulture);
}
