using PAO.Core.Areas.Booking.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Booking.Services.Shared;

/// <summary>The Booking contract for the other areas.</summary>
public sealed class BookingSharedService(BookingQueries queries, IClock clock, IMapper mapper) : IBookingSharedService
{
    /// <inheritdoc />
    public async Task<BookingDetails> GetBooking(Guid bookingId, CancellationToken cancellationToken) =>
        mapper.Map<StoredBooking, BookingDetails>(await queries.Get(bookingId, cancellationToken));

    /// <inheritdoc />
    public Task<int> CountActiveJobs(Guid merchantId, CancellationToken cancellationToken) =>
        queries.CountActive(merchantId, Guid.Empty, cancellationToken);

    /// <inheritdoc />
    public async Task<MerchantStats> GetMerchantStats(Guid merchantId, CancellationToken cancellationToken)
    {
        var (completed, cancellations) = await queries.Stats(merchantId, clock.Now - TimeSpan.FromDays(30), cancellationToken);
        return new MerchantStats { CompletedJobs = completed, Cancellations30d = cancellations };
    }

    /// <summary>Either side's bookings: the customer's first, then the merchant's, up to `limit` of each.</summary>
    public async Task<IReadOnlyList<BookingSummary>> ListRecentBookings(Guid partyId, int limit, CancellationToken cancellationToken)
    {
        var page = new BookingPage(null, null, limit);
        var asCustomer = await queries.List(partyId, false, BookingStates.All, page, cancellationToken);
        var asMerchant = await queries.List(partyId, true, BookingStates.All, page, cancellationToken);
        return mapper.MapAll<BookingRow, BookingSummary>([.. asCustomer, .. asMerchant]);
    }
}
