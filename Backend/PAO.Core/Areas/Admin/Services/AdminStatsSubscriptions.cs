using System.Text.Json;
using PAO.Core.Areas.Admin.Repositories;
using PAO.EF;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Verification;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>Keeps the dashboard read model current from other areas' events, each once per event (A-09).</summary>
public sealed class AdminStatsSubscriptions(IdempotentEventHandler idempotent) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        var handlers = new Dictionary<string, Func<PaoDbContext, Envelope, CancellationToken, Task>>
        {
            [IdentityEvents.AccountCreated] = (db, e, ct) =>
                Text(e, "role") == Roles.Provider ? DashboardRepository.AddProvider(db, Id(e, "accountId"), ct) : Task.CompletedTask,
            [IdentityEvents.AccountStatusChanged] = (db, e, ct) =>
                RolesOf(e).Contains(Roles.Provider) ? DashboardRepository.SetStatus(db, Id(e, "accountId"), Text(e, "to"), ct) : Task.CompletedTask,
            [IdentityEvents.AccountDeleted] = (db, e, ct) => DashboardRepository.DeleteProvider(db, Id(e, "accountId"), ct),
            [VerificationEvents.ProviderLevelChanged] = (db, e, ct) => DashboardRepository.SetLevel(db, Id(e, "providerId"), Level(e), ct),
            [BookingEvents.BookingRequested] = (db, e, ct) => DashboardRepository.BumpBookings(db, Day(e), 1, 0, ct),
            [BookingEvents.BookingCompleted] = (db, e, ct) => DashboardRepository.BumpBookings(db, Day(e), 0, 1, ct),
        };
        foreach (var (name, apply) in handlers)
        {
            bus.Subscribe(name, Schemas.Admin, idempotent.Wrap(Schemas.Admin, name, apply));
        }
    }

    /// <summary>The Dhaka day an event happened on.</summary>
    private static DateOnly Day(Envelope e) => DateOnly.FromDateTime(e.OccurredAt.ToOffset(DhakaTime.Offset).DateTime);

    // A field the handler needs; a malformed event fails so the relay retries it.
    private static JsonElement Field(Envelope e, string name, JsonValueKind kind) =>
        e.Payload.ValueKind == JsonValueKind.Object && e.Payload.TryGetProperty(name, out var v) && v.ValueKind == kind
            ? v : throw new FormatException($"decode {e.Name}: {name} is missing");

    private static string Text(Envelope e, string name) => Field(e, name, JsonValueKind.String).GetString()!;

    private static Guid Id(Envelope e, string name) => Guid.Parse(Text(e, name));

    private static int Level(Envelope e) => Field(e, "to", JsonValueKind.Number).GetInt32();

    private static IEnumerable<string?> RolesOf(Envelope e) => Field(e, "roles", JsonValueKind.Array).EnumerateArray().Select(r => r.ToString());
}
