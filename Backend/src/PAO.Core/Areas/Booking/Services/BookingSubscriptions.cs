using PAO.Core.Areas.Booking.Features.Erasure.Commands;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>Erasure: a deleted account's personal details leave the booking snapshots (PRD §11).</summary>
public sealed class BookingSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus) => bus.Subscribe(IdentityEvents.AccountDeleted, "booking", async (envelope, cancellationToken) =>
    {
        var account = Guid.Parse(new EventPayload(envelope).Id("accountId"));
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new EraseBookingSnapshots(account), cancellationToken);
    });
}
