using PAO.Core.Areas.Customer.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Customer.Services;

/// <summary>Customer profiles (C-01): the stored profile with the phone and a signed photo URL.</summary>
public sealed class CustomerProfiles(CustomerRepository repository, CustomerPeers peers, IClock clock)
{
    /// <summary>The profile with the account phone and, with a photo, its URL.</summary>
    public async Task<CustomerProfileDetails> Details(Guid id, CancellationToken cancellationToken)
    {
        var profile = await repository.Get(id, cancellationToken);
        var (phone, _) = await peers.Account(id, cancellationToken);
        var url = profile.PhotoMediaId is { } photo ? await peers.PhotoUrl(id, photo, cancellationToken) : null;
        return new CustomerProfileDetails(profile, phone, url);
    }

    /// <summary>Creates or updates the profile; a photo must be the customer's own confirmed avatar.</summary>
    public async Task<CustomerProfileDetails> Save(Guid id, CustomerProfileInput input, CancellationToken cancellationToken)
    {
        var name = input.Name.Trim();
        if (CustomerRules.ProfileProblem(name, input.Language) is not null)
        {
            throw new DomainException(CustomerReasons.Invalid);
        }
        if (input.PhotoMediaId is { } photo)
        {
            await peers.AttachAvatar(id, photo, cancellationToken);
        }
        var (phone, status) = await peers.Account(id, cancellationToken);
        var stored = new StoredCustomer(id, name, input.PhotoMediaId, input.Language, clock.Now, phone, status);
        await repository.Save(stored, new CustomerProfileSaved { CustomerId = id, CustomerName = name }, cancellationToken);
        return await Details(id, cancellationToken);
    }
}
