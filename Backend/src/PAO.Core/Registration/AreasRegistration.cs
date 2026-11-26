namespace PAO.Core.Registration;

/// <summary>Every area of the API, one ASP.NET area per module (ADR-0034).</summary>
public static class AreasRegistration
{
    /// <summary>The area names, in the order the modules were listed in the PRD.</summary>
    public static readonly IReadOnlyList<string> Names = ["Identity", "Customer", "Merchant", "Verification", "Catalog", "Booking", "Rating", "Notification", "Media", "Audit", "Admin", "Billing"];

    /// <summary>Adds every area through its own `Add{Area}Area` method.</summary>
    public static IServiceCollection AddAreas(this IServiceCollection services) => services
            .AddIdentityArea()
            .AddCustomerArea()
            .AddMerchantArea()
            .AddVerificationArea()
            .AddCatalogArea()
            .AddBookingArea()
            .AddRatingArea()
            .AddNotificationArea()
            .AddMediaArea()
            .AddAuditArea()
            .AddAdminArea()
            .AddBillingArea();
}
