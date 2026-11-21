using PAO.Core.Areas.Customer.Services;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.Profile.Queries;

/// <summary>The customer's own profile (C-01); `customer.not_found` before it is set up.</summary>
public sealed record GetCustomerProfile(Guid CustomerId) : IQuery<CustomerProfileView>;

/// <summary>Answers <see cref="GetCustomerProfile"/>.</summary>
public sealed class GetCustomerProfileHandler(CustomerProfiles profiles, IMapper mapper) : IRequestHandler<GetCustomerProfile, CustomerProfileView>
{
    /// <inheritdoc />
    public async Task<CustomerProfileView> Handle(GetCustomerProfile request, CancellationToken cancellationToken) =>
        mapper.Map<CustomerProfileDetails, CustomerProfileView>(await profiles.Details(request.CustomerId, cancellationToken));
}
