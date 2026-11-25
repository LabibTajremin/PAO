using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Subscriptions.Commands;

/// <summary>The merchant accepts a requested subscription once (ADR-0041 §2); the due limit applies as for a booking.</summary>
public sealed record AcceptSubscription(Guid ProviderId, Guid SubscriptionId) : ICommand<SubscriptionView>;

/// <summary>The merchant declines a requested subscription; the reason is stored as "reason: note".</summary>
public sealed record DeclineSubscription(Guid ProviderId, Guid SubscriptionId, ReasonInput Input) : ICommand<SubscriptionView>;

/// <summary>The merchant declines one date before its cutoff.</summary>
public sealed record DeclineDelivery(Guid ProviderId, Guid SubscriptionId, DateOnly Date) : ICommand<DeliveryDateView>;

/// <summary>Checks <see cref="DeclineSubscription"/>.</summary>
public sealed class DeclineSubscriptionValidator : AbstractValidator<DeclineSubscription>
{
    /// <summary>A reason is required; the spec lists the keys.</summary>
    public DeclineSubscriptionValidator() => RuleFor(r => r.Input.Reason).NotEmpty();
}

/// <summary>Answers <see cref="AcceptSubscription"/> and <see cref="DeclineSubscription"/>.</summary>
public sealed class AnswerSubscriptionHandler(SubscriptionAccess access, BookingPeers peers, IMapper mapper)
    : IRequestHandler<AcceptSubscription, SubscriptionView>, IRequestHandler<DeclineSubscription, SubscriptionView>
{
    /// <inheritdoc />
    public async Task<SubscriptionView> Handle(AcceptSubscription request, CancellationToken cancellationToken)
    {
        await peers.EnsureCanAccept(request.ProviderId, cancellationToken);
        var s = await access.Change(request.SubscriptionId, request.ProviderId, Side.Provider, s =>
        {
            Requested(s);
            s.Status = SubscriptionStatus.Active;
            s.AcceptedAt = access.Now;
            return access.Event(new SubscriptionAccepted(), s);
        }, cancellationToken);
        return mapper.Provider(s, await access.Upcoming(s, cancellationToken));
    }

    /// <inheritdoc />
    public async Task<SubscriptionView> Handle(DeclineSubscription request, CancellationToken cancellationToken)
    {
        var reason = string.IsNullOrWhiteSpace(request.Input.Note) ? request.Input.Reason : $"{request.Input.Reason}: {request.Input.Note.Trim()}";
        var s = await access.Change(request.SubscriptionId, request.ProviderId, Side.Provider, s =>
        {
            Requested(s);
            s.Status = SubscriptionStatus.Declined;
            s.DeclineReason = reason;
            return access.Event(new SubscriptionDeclined { Reason = request.Input.Reason }, s);
        }, cancellationToken);
        return mapper.Provider(s, await access.Upcoming(s, cancellationToken));
    }

    private static void Requested(StoredSubscription s)
    {
        if (s.Status != SubscriptionStatus.Requested)
        {
            throw new DomainException(BookingReasons.InvalidTransition);
        }
    }
}

/// <summary>Answers <see cref="DeclineDelivery"/>.</summary>
public sealed class DeclineDeliveryHandler(SubscriptionAccess access) : IRequestHandler<DeclineDelivery, DeliveryDateView>
{
    /// <inheritdoc />
    public async Task<DeliveryDateView> Handle(DeclineDelivery request, CancellationToken cancellationToken)
    {
        var holidays = await access.Holidays(cancellationToken);
        var s = await access.Change(request.SubscriptionId, request.ProviderId, Side.Provider, s =>
        {
            DeliveryDates.EnsureChangeable(s, request.Date, access.Now, holidays);
            s.Dates[request.Date] = new SubscriptionDate(request.Date, DateState.Declined, null, null, null);
            return access.Event(new DeliveryDeclined { Date = EarningsCalendar.Iso(request.Date) }, s);
        }, cancellationToken);
        return SubscriptionSides.Date(SubscriptionDays.Day(s, request.Date, access.Now));
    }
}
