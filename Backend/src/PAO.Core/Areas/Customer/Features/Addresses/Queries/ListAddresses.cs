using PAO.Core.Areas.Customer.Repositories;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.Addresses.Queries;

/// <summary>The customer's saved addresses, default first (C-02).</summary>
public sealed record ListAddresses(Guid CustomerId) : IQuery<AddressListView>;

/// <summary>Answers <see cref="ListAddresses"/>.</summary>
public sealed class ListAddressesHandler(AddressRepository addresses, IMapper mapper) : IRequestHandler<ListAddresses, AddressListView>
{
    /// <inheritdoc />
    public async Task<AddressListView> Handle(ListAddresses request, CancellationToken cancellationToken) =>
        new() { Items = mapper.MapAll<SavedAddress, AddressView>(await addresses.List(request.CustomerId, cancellationToken)) };
}
