using PAO.Core.Areas.Customer.Repositories;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Customer.Services.Shared;

/// <summary>The Customer contract for the other areas.</summary>
public sealed class CustomerSharedService(CustomerRepository customers, AddressRepository addresses, CustomerPeers peers, IMapper mapper)
    : ICustomerSharedService
{
    /// <inheritdoc />
    public Task<CustomerProfile> GetCustomer(Guid customerId, CancellationToken cancellationToken) =>
        customers.Get(customerId, cancellationToken);

    /// <inheritdoc />
    public async Task<CustomerAddress> GetAddress(Guid customerId, Guid addressId, CancellationToken cancellationToken) =>
        mapper.Map<SavedAddress, CustomerAddress>(await addresses.Get(customerId, addressId, cancellationToken));

    /// <inheritdoc />
    public async Task<bool> IsInServiceArea(GeoPoint point, CancellationToken cancellationToken) =>
        LaunchArea.Covers(await peers.LaunchAreaGeoJson(cancellationToken), point);

    /// <inheritdoc />
    public Task<IReadOnlyList<CustomerRecord>> SearchCustomers(CustomerQuery query, CancellationToken cancellationToken) =>
        customers.Search(query, cancellationToken);
}
