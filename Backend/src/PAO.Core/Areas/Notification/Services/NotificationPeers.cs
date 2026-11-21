using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>What notifications say about a booking.</summary>
public sealed record BookingFacts(string Number, string ServiceEn, string ServiceBn, string Area, string ProviderName, string CustomerName);

/// <summary>
/// Reads languages and booking text from the other areas. Their contracts are resolved on
/// first use: those areas notify through this one, so a constructor dependency would be a cycle.
/// </summary>
public sealed class NotificationPeers(IServiceProvider services)
{
    /// <summary>A recipient's language in an app; Bangla for anyone without a profile (04-decisions).</summary>
    public async Task<string> Language(Guid account, string app, CancellationToken cancellationToken)
    {
        try
        {
            return app == NotificationApp.Customer
                ? (await services.GetRequiredService<ICustomerSharedService>().GetCustomer(account, cancellationToken)).Language
                : (await services.GetRequiredService<IMerchantSharedService>().GetMerchant(account, cancellationToken)).Language;
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            return "bn";
        }
    }

    /// <summary>The booking's details; null when there is no such booking.</summary>
    public async Task<BookingFacts?> Booking(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var b = await services.GetRequiredService<IBookingSharedService>().GetBooking(id, cancellationToken);
            return new BookingFacts(b.Number, b.ServiceName.En, b.ServiceName.Bn, b.Area, b.ProviderName, b.CustomerName);
        }
        catch (DomainException error) when (error.Reason == BookingErrors.NotFound)
        {
            return null;
        }
    }
}
