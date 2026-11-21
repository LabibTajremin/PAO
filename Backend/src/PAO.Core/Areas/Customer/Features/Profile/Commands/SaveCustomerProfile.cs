using PAO.Core.Areas.Customer.Services;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.Profile.Commands;

/// <summary>Creates or updates the customer's profile and publishes `CustomerProfileSaved`.</summary>
public sealed record SaveCustomerProfile(Guid CustomerId, CustomerProfileInput Input) : ICommand<CustomerProfileView>;

/// <summary>Answers <see cref="SaveCustomerProfile"/>; the name and language rules live in <see cref="CustomerRules"/>.</summary>
public sealed class SaveCustomerProfileHandler(CustomerProfiles profiles, IMapper mapper) : IRequestHandler<SaveCustomerProfile, CustomerProfileView>
{
    /// <inheritdoc />
    public async Task<CustomerProfileView> Handle(SaveCustomerProfile request, CancellationToken cancellationToken) =>
        mapper.Map<CustomerProfileDetails, CustomerProfileView>(await profiles.Save(request.CustomerId, request.Input, cancellationToken));
}
