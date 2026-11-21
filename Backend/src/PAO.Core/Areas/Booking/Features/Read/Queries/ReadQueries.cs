using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Read.Queries;

/// <summary>
/// A booking for one side, with whether the caller already reviewed it, so the apps stop
/// offering the review (C-11, P-09) once it is given.
/// </summary>
public sealed record GetBooking(Guid PartyId, Side Side, Guid BookingId) : IQuery<BookingView>;

/// <summary>The code the customer reads to the provider, from acceptance until the job starts.</summary>
public sealed record GetStartCode(Guid CustomerId, Guid BookingId) : IQuery<StartCodeView>;

/// <summary>A completed booking's receipt for either side.</summary>
public sealed record GetReceipt(Guid PartyId, Guid BookingId) : IQuery<ReceiptView>;

/// <summary>A party's bookings on an app tab, newest first.</summary>
public sealed record ListBookings(Guid PartyId, Side Side, string Tab, string? Cursor, int? Limit) : IQuery<BookingListView>;

/// <summary>Checks <see cref="GetBooking"/>.</summary>
public sealed class GetBookingValidator : AbstractValidator<GetBooking>
{
    /// <summary>Detail views belong to one side.</summary>
    public GetBookingValidator() => RuleFor(r => r.Side).NotEqual(Side.Any);
}

/// <summary>Checks <see cref="ListBookings"/>.</summary>
public sealed class ListBookingsValidator : AbstractValidator<ListBookings>
{
    /// <summary>A known tab.</summary>
    public ListBookingsValidator() => RuleFor(r => r.Tab).Must(tab => BookingStates.Tab(tab, false) is not null);
}

/// <summary>Answers <see cref="GetBooking"/>; only completed bookings can be reviewed, so others answer without asking Rating.</summary>
public sealed class GetBookingHandler(BookingAccess access, BookingPeers peers, IMapper mapper) : IRequestHandler<GetBooking, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(GetBooking request, CancellationToken cancellationToken)
    {
        var b = await access.Owned(request.BookingId, request.PartyId, request.Side, cancellationToken);
        var reviewed = b.Status == BookingStatus.Completed && await peers.HasReviewed(b.Id, request.PartyId, cancellationToken);
        return request.Side == Side.Customer ? mapper.Customer(b, reviewed) : mapper.Provider(b, reviewed);
    }
}

/// <summary>Answers <see cref="GetStartCode"/>.</summary>
public sealed class GetStartCodeHandler(BookingAccess access) : IRequestHandler<GetStartCode, StartCodeView>
{
    /// <inheritdoc />
    public async Task<StartCodeView> Handle(GetStartCode request, CancellationToken cancellationToken)
    {
        var b = await access.Owned(request.BookingId, request.CustomerId, Side.Customer, cancellationToken);
        return BookingStates.CodeStates.Contains(b.Status) ? new StartCodeView { Code = b.StartCode } : throw new DomainException(BookingReasons.InvalidTransition);
    }
}

/// <summary>Answers <see cref="GetReceipt"/>.</summary>
public sealed class GetReceiptHandler(BookingAccess access, IMapper mapper) : IRequestHandler<GetReceipt, ReceiptView>
{
    /// <inheritdoc />
    public async Task<ReceiptView> Handle(GetReceipt request, CancellationToken cancellationToken)
    {
        var b = await access.Owned(request.BookingId, request.PartyId, Side.Any, cancellationToken);
        return b.Status == BookingStatus.Completed ? mapper.Map<StoredBooking, ReceiptView>(b) : throw new DomainException(BookingReasons.InvalidTransition);
    }
}

/// <summary>Answers <see cref="ListBookings"/>; a provider's requests have their own tab, their upcoming tab holds accepted jobs.</summary>
public sealed class ListBookingsHandler(BookingAccess access, IMapper mapper) : IRequestHandler<ListBookings, BookingListView>
{
    /// <inheritdoc />
    public async Task<BookingListView> Handle(ListBookings request, CancellationToken cancellationToken)
    {
        var asProvider = request.Side == Side.Provider;
        var (size, page) = BookingPaging.Page(request.Cursor, request.Limit);
        var rows = await access.Queries.List(request.PartyId, asProvider, BookingStates.Tab(request.Tab, asProvider)!, page, cancellationToken);
        return BookingPaging.List(mapper, rows, size, r => asProvider ? r.CustomerName : r.ProviderName);
    }
}
