using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Events;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Progress.Commands;

/// <summary>The provider sets off (transition 5) or arrives (transition 6).</summary>
public sealed record AdvanceJob(Guid ProviderId, Guid BookingId, string To) : ICommand<BookingView>;

/// <summary>
/// The provider enters the customer's start code (transition 7). It writes in its own
/// transaction: a wrong code is saved before it is reported, so the lockout survives retries.
/// </summary>
public sealed record StartJob(Guid ProviderId, Guid BookingId, string Code) : IRequest<BookingView>;

/// <summary>The provider proposes extra catalog items of the booked service (PRD §5).</summary>
public sealed record ProposeExtras(Guid ProviderId, Guid BookingId, ExtrasInput Input) : ICommand<BookingView>;

/// <summary>The customer approves or declines the pending extras.</summary>
public sealed record DecideExtras(Guid CustomerId, Guid BookingId, ExtrasDecisionInput Input) : ICommand<BookingView>;

/// <summary>The provider completes the job with the cash confirmed (transition 8, D4).</summary>
public sealed record CompleteJob(Guid ProviderId, Guid BookingId, bool CashReceived) : ICommand<BookingView>;

/// <summary>Checks <see cref="AdvanceJob"/>.</summary>
public sealed class AdvanceJobValidator : AbstractValidator<AdvanceJob>
{
    /// <summary>Only the two moves the routes make.</summary>
    public AdvanceJobValidator() => RuleFor(r => r.To).Must(to => to is BookingStatus.OnTheWay or BookingStatus.Arrived);
}

/// <summary>Checks <see cref="ProposeExtras"/>.</summary>
public sealed class ProposeExtrasValidator : AbstractValidator<ProposeExtras>
{
    /// <summary>One to ten items, as `booking.invalid`.</summary>
    public ProposeExtrasValidator() => RuleFor(r => r.Input.Items).Custom((items, _) =>
    {
        if (items.Count is 0 or > 10)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
    });
}

/// <summary>Answers <see cref="AdvanceJob"/>.</summary>
public sealed class AdvanceJobHandler(BookingAccess access, IMapper mapper) : IRequestHandler<AdvanceJob, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(AdvanceJob request, CancellationToken cancellationToken)
    {
        var b = await access.AsProvider(request.BookingId, request.ProviderId, b =>
        {
            BookingAccess.Refuse(BookingTransitions.Advance(b, request.To, access.Stamp()));
            return request.To == BookingStatus.OnTheWay ? access.Event(new ProviderOnTheWay(), b) : access.Event(new ProviderArrived(), b);
        }, cancellationToken);
        return mapper.Provider(b);
    }
}

/// <summary>Answers <see cref="StartJob"/>.</summary>
public sealed class StartJobHandler(BookingAccess access, BookingPeers peers, IMapper mapper) : IRequestHandler<StartJob, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(StartJob request, CancellationToken cancellationToken)
    {
        var rules = await peers.Rules(cancellationToken);
        var limits = new CodeLimits(rules.StartCodeMaxAttempts, TimeSpan.FromMilliseconds(rules.StartCodeLockoutMs));
        string? wrong = null;
        var b = await access.AsProvider(request.BookingId, request.ProviderId, b =>
        {
            var refused = BookingTransitions.Start(b, request.Code, access.Stamp(), limits);
            if (refused == BookingReasons.CodeWrong)
            {
                wrong = refused;
                return null;
            }
            BookingAccess.Refuse(refused);
            return access.Event(new BookingStarted(), b);
        }, cancellationToken);
        BookingAccess.Refuse(wrong);
        return mapper.Provider(b);
    }
}

/// <summary>Answers <see cref="ProposeExtras"/>.</summary>
public sealed class ProposeExtrasHandler(BookingAccess access, BookingPricing pricing, IMapper mapper) : IRequestHandler<ProposeExtras, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(ProposeExtras request, CancellationToken cancellationToken)
    {
        var b = await access.Change(request.BookingId, request.ProviderId, Side.Provider, async b =>
        {
            // Positions continue after the bill and every proposal not already on it.
            var next = b.Lines.Count + b.Proposals.Where(p => p.Status != "approved").Sum(p => p.Lines.Count);
            var id = access.NewId();
            var lines = await pricing.Lines(b.ServiceId, request.Input.Items, next, cancellationToken);
            var proposal = new ExtrasProposal { Id = id, Status = "pending", ProposedAt = access.Now, Lines = [.. lines.Select(l => l with { Extra = true, ProposalId = id })] };
            BookingAccess.Refuse(BookingTransitions.Propose(b, proposal));
            var e = access.Event(
                new ExtraItemsProposed { ProposalId = proposal.Id, AddedPaisa = proposal.AddedPaisa, NewTotalPaisa = b.TotalPaisa + proposal.AddedPaisa }, b);
            return (IReadOnlyList<IDomainEvent>)[e];
        }, cancellationToken);
        return mapper.Provider(b);
    }
}

/// <summary>Answers <see cref="DecideExtras"/>.</summary>
public sealed class DecideExtrasHandler(BookingAccess access, IMapper mapper) : IRequestHandler<DecideExtras, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(DecideExtras request, CancellationToken cancellationToken)
    {
        var (proposalId, approve) = (request.Input.ProposalId, request.Input.Approve);
        var b = await access.Change(request.BookingId, request.CustomerId, Side.Customer, b =>
        {
            BookingAccess.Refuse(BookingTransitions.Decide(b, proposalId, approve, access.Now));
            var e = access.Event(new ExtraItemsDecided { ProposalId = proposalId, Approved = approve }, b);
            return Task.FromResult<IReadOnlyList<IDomainEvent>>([e]);
        }, cancellationToken);
        return mapper.Customer(b);
    }
}

/// <summary>
/// Answers <see cref="CompleteJob"/>. `booking.BookingCompleted` carries the provider and the
/// final total, which is what Billing debits its commission from (ADR-0035 §2).
/// </summary>
public sealed class CompleteJobHandler(BookingAccess access, IMapper mapper) : IRequestHandler<CompleteJob, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(CompleteJob request, CancellationToken cancellationToken)
    {
        var b = await access.AsProvider(request.BookingId, request.ProviderId, b =>
        {
            BookingAccess.Refuse(BookingTransitions.Complete(b, request.CashReceived, access.Stamp()));
            return access.Event(new BookingCompleted
            {
                TotalPaisa = b.TotalPaisa,
                CustomerName = b.Customer.Name,
                ProviderName = b.Provider.Name,
                ServiceName = b.ServiceName,
            }, b);
        }, cancellationToken);
        return mapper.Provider(b);
    }
}
