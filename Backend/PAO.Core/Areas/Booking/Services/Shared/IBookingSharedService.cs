using PAO.Lib.Areas.Booking;

namespace PAO.Core.Areas.Booking.Services.Shared;

/// <summary>
/// What other areas may ask of the Booking area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IBookingSharedService
{
    /// <summary>Returns a booking with its parties and snapshots, or throws `booking.not_found`.</summary>
    Task<BookingDetails> GetBooking(Guid bookingId, CancellationToken cancellationToken);

    /// <summary>Returns how many accepted-but-unfinished jobs the merchant has; the MVP allows one active ASAP job at a time (PRD §5).</summary>
    Task<int> CountActiveJobs(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Returns completed jobs and recent merchant cancellations, for search cards and quality thresholds (D13).</summary>
    Task<MerchantStats> GetMerchantStats(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Returns a party's latest bookings for admin detail pages.</summary>
    Task<IReadOnlyList<BookingSummary>> ListRecentBookings(Guid partyId, int limit, CancellationToken cancellationToken);
}
