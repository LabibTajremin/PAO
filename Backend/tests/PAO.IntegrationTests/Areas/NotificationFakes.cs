using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.IntegrationTests.Areas;

/// <summary>The people and booking the notification tests talk about; the real areas are ported later.</summary>
public sealed class NotificationWorld
{
    public Guid Customer { get; } = Guid.NewGuid();
    public Guid Provider { get; } = Guid.NewGuid();
    public Guid BanglaProvider { get; } = Guid.NewGuid();
    public Guid Booking { get; } = Guid.NewGuid();
    public Guid BrokenBooking { get; } = Guid.NewGuid();
    public const string Number = "PAO-100001";
}

/// <summary>The customer speaks Bangla by default; nobody else has a profile.</summary>
public sealed class FakeCustomers(NotificationWorld world) : ICustomerSharedService
{
    public Task<CustomerProfile> GetCustomer(Guid customerId, CancellationToken cancellationToken) => customerId == world.Customer
        ? Task.FromResult(new CustomerProfile { Id = customerId, Name = "Nusrat", Language = "bn" })
        : throw new DomainException(CustomerErrors.NotFound);

    public Task<CustomerAddress> GetAddress(Guid customerId, Guid addressId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<bool> IsInServiceArea(GeoPoint point, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<CustomerRecord>> SearchCustomers(CustomerQuery query, CancellationToken cancellationToken) => throw new NotSupportedException();
}

/// <summary>The provider reads English.</summary>
public sealed class FakeMerchants(NotificationWorld world) : IMerchantSharedService
{
    public Task<MerchantProfile> GetMerchant(Guid merchantId, CancellationToken cancellationToken) => merchantId == world.Provider
        ? Task.FromResult(new MerchantProfile
        {
            Id = merchantId,
            FullName = "Rahim",
            Gender = "male",
            PresentAddress = "x",
            PermanentAddress = "x",
            Phone = "01712345678",
            ServiceIds = [],
            ExperienceYears = 1,
            WorkingRadiusM = 5000,
            Language = "en",
        })
        : throw new DomainException(MerchantErrors.NotFound);

    public Task<IReadOnlyDictionary<Guid, MerchantProfile>> GetMerchants(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<bool> IsAvailable(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<NearbyMerchant>> FindNearby(NearbyQuery query, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<EnrolmentStatus> Enrolment(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<EnrolmentStatus> MarkStepDone(Guid merchantId, string step, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task MarkSubmitted(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task ForceOffline(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<MerchantRecord>> SearchMerchants(MerchantQuery query, CancellationToken cancellationToken) => throw new NotSupportedException();
}

/// <summary>One booking; another fails as a database outage would; any other is unknown.</summary>
public sealed class FakeBookings(NotificationWorld world) : IBookingSharedService
{
    public Task<BookingDetails> GetBooking(Guid bookingId, CancellationToken cancellationToken)
    {
        if (bookingId == world.BrokenBooking)
        {
            throw new InvalidOperationException("db down");
        }
        return bookingId == world.Booking
            ? Task.FromResult(new BookingDetails
            {
                Id = bookingId,
                Number = NotificationWorld.Number,
                Status = BookingStatus.Requested,
                CustomerId = world.Customer,
                ProviderId = world.Provider,
                ServiceId = Guid.NewGuid(),
                ServiceName = new Text { En = "Fan install", Bn = "ফ্যান লাগানো" },
                CustomerName = "Nusrat",
                ProviderName = "Rahim",
                Area = "Gulshan",
                TotalPaisa = 50_000,
                CreatedAt = DateTimeOffset.UtcNow,
            })
            : throw new DomainException(BookingErrors.NotFound);
    }

    public Task<int> CountActiveJobs(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<MerchantStats> GetMerchantStats(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<BookingSummary>> ListRecentBookings(Guid partyId, int limit, CancellationToken cancellationToken) => throw new NotSupportedException();
}
