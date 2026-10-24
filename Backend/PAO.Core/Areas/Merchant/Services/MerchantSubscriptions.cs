using PAO.EF;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Areas.Verification;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>The Merchant area's read-model handlers, each applied once per event (handler name = event name, as NestJS).</summary>
public sealed class MerchantSubscriptions(IdempotentEventHandler idempotent, MerchantReadModel model) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        var handlers = new Dictionary<string, Func<PaoDbContext, EventPayload, Envelope, CancellationToken, Task>>
        {
            [VerificationEvents.ProviderLevelChanged] = (db, p, _, ct) => model.LevelChanged(db, p, ct),
            [IdentityEvents.AccountStatusChanged] = (db, p, _, ct) => model.StatusChanged(db, p, ct),
            [IdentityEvents.AccountDeleted] = (db, p, _, ct) => model.Deleted(db, p, ct),
            [RatingEvents.ReviewSubmitted] = (db, p, _, ct) => model.ReviewSubmitted(db, p, ct),
            [BookingEvents.BookingCompleted] = (db, p, _, ct) => model.BookingCompleted(db, p, ct),
            [BookingEvents.BookingCancelled] = (db, p, e, ct) => model.BookingCancelled(db, p, e.OccurredAt, ct),
            [AdminEvents.ComplaintResolved] = (db, p, _, ct) => model.ComplaintResolved(db, p, ct),
        };
        foreach (var (name, apply) in handlers)
        {
            bus.Subscribe(name, Schemas.Merchant, idempotent.Wrap(Schemas.Merchant, name, (db, envelope, ct) => apply(db, new EventPayload(envelope), envelope, ct)));
        }
    }
}
