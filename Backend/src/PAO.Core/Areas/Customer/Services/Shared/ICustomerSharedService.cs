using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Customer.Services.Shared;

/// <summary>
/// What other areas may ask of the Customer area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface ICustomerSharedService
{
    /// <summary>Returns a customer profile, or throws `customer.not_found`.</summary>
    Task<CustomerProfile> GetCustomer(Guid customerId, CancellationToken cancellationToken);

    /// <summary>Returns one of the customer's saved addresses with its exact location, or throws `customer.address_not_found`. Callers reveal it to a merchant only after acceptance (PRD §11).</summary>
    Task<CustomerAddress> GetAddress(Guid customerId, Guid addressId, CancellationToken cancellationToken);

    /// <summary>Reports whether a point lies inside an active launch area (C35).</summary>
    Task<bool> IsInServiceArea(GeoPoint point, CancellationToken cancellationToken);

    /// <summary>Lists customers with a profile for the admin console, newest first (A-05).</summary>
    Task<IReadOnlyList<CustomerRecord>> SearchCustomers(CustomerQuery query, CancellationToken cancellationToken);
}
