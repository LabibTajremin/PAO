using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Events;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Respond.Commands;

/// <summary>The provider accepts a request (transition 1); the start code is made now and shown only to the customer.</summary>
public sealed record AcceptBooking(Guid ProviderId, Guid BookingId) : ICommand<BookingView>;

/// <summary>The provider rejects a request (transition 2); the reason is stored as "reason: note".</summary>
public sealed record RejectBooking(Guid ProviderId, Guid BookingId, ReasonInput Input) : ICommand<BookingView>;

/// <summary>A side cancels (transitions 4, 9 and 10); the reason is stored as "reason: note".</summary>
public sealed record CancelBooking(Side Side, Guid PartyId, Guid BookingId, ReasonInput Input) : ICommand<BookingView>;

/// <summary>Checks <see cref="RejectBooking"/>.</summary>
public sealed class RejectBookingValidator : AbstractValidator<RejectBooking>
{
    /// <summary>A reason is required; the spec lists the keys.</summary>
    public RejectBookingValidator() => RuleFor(r => r.Input.Reason).NotEmpty();
}

/// <summary>Checks <see cref="CancelBooking"/>.</summary>
public sealed class CancelBookingValidator : AbstractValidator<CancelBooking>
{
    /// <summary>A reason from a customer or a provider.</summary>
    public CancelBookingValidator()
    {
        RuleFor(r => r.Input.Reason).NotEmpty();
        RuleFor(r => r.Side).NotEqual(Side.Any);
    }
}

/// <summary>Answers <see cref="AcceptBooking"/>; Billing's due limit is checked first (ADR-0035 §3).</summary>
public sealed class AcceptBookingHandler(BookingAccess access, BookingPeers peers, IMapper mapper) : IRequestHandler<AcceptBooking, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(AcceptBooking request, CancellationToken cancellationToken)
    {
        await peers.EnsureCanAccept(request.ProviderId, cancellationToken);
        var b = await access.AsProvider(request.BookingId, request.ProviderId, b =>
        {
            BookingAccess.Refuse(BookingTransitions.Accept(b, access.Stamp()));
            b.StartCode = BookingStates.NewStartCode();
            return access.Event(new BookingAccepted(), b);
        }, cancellationToken);
        return mapper.Provider(b);
    }
}

/// <summary>Answers <see cref="RejectBooking"/>.</summary>
public sealed class RejectBookingHandler(BookingAccess access, IMapper mapper) : IRequestHandler<RejectBooking, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(RejectBooking request, CancellationToken cancellationToken)
    {
        var reason = request.Input.Stored;
        var b = await access.AsProvider(request.BookingId, request.ProviderId, b =>
        {
            BookingAccess.Refuse(BookingTransitions.Reject(b, access.Stamp(), reason));
            return access.Event(new BookingRejected { Reason = reason }, b);
        }, cancellationToken);
        return mapper.Provider(b);
    }
}

/// <summary>Answers <see cref="CancelBooking"/>; a provider's cancellation after acceptance counts against quality (PRD §6.4).</summary>
public sealed class CancelBookingHandler(BookingAccess access, IMapper mapper) : IRequestHandler<CancelBooking, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(CancelBooking request, CancellationToken cancellationToken)
    {
        var reason = request.Input.Stored;
        var actor = request.Side == Side.Customer ? BookingActor.Customer : BookingActor.Provider;
        var b = await access.Change(request.BookingId, request.PartyId, request.Side, b =>
        {
            BookingAccess.Refuse(BookingTransitions.Cancel(b, access.Stamp(), actor, reason));
            var e = access.Event(new BookingCancelled { By = actor, Reason = reason, AfterAcceptance = b.AcceptedAt is not null }, b);
            return Task.FromResult<IReadOnlyList<IDomainEvent>>([e]);
        }, cancellationToken);
        return request.Side == Side.Customer ? mapper.Customer(b) : mapper.Provider(b);
    }
}

/// <summary>
/// Answers <see cref="ExpireDueRequests"/>: each due request times out in its own
/// transaction, so one failure leaves the others done and the next sweep catches up.
/// </summary>
public sealed class ExpireDueRequestsHandler(BookingAccess access) : IRequestHandler<ExpireDueRequests, int>
{
    /// <inheritdoc />
    public async Task<int> Handle(ExpireDueRequests request, CancellationToken cancellationToken)
    {
        var now = access.Now;
        var expired = 0;
        foreach (var id in await access.Queries.Due(now, cancellationToken))
        {
            await access.Repository.Change(id, b =>
            {
                // A provider answering at the same moment already moved the booking on.
                if (BookingTransitions.TimeOut(b, new Stamp(now, access.NewId())) is not null)
                {
                    return Task.FromResult<IReadOnlyList<IDomainEvent>>([]);
                }
                expired++;
                return Task.FromResult<IReadOnlyList<IDomainEvent>>([access.Event(new BookingTimedOut(), b)]);
            }, cancellationToken);
        }
        return expired;
    }
}
