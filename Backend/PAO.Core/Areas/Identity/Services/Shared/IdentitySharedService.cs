using PAO.Core.Areas.Identity.Features.SetAccountStatus.Commands;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Services.Shared;

/// <summary>The Identity contract for the other areas; its errors carry the contract's reasons.</summary>
public sealed class IdentitySharedService(IIdentityRepository repository, PhoneCodes codes, IMediator mediator, IMapper mapper) : IIdentitySharedService
{
    /// <inheritdoc />
    public async Task<Account> GetAccount(Guid accountId, CancellationToken cancellationToken) =>
        mapper.Map<AccountRecord, Account>(await repository.AccountById(accountId, cancellationToken));

    /// <inheritdoc />
    public async Task<bool> HasRole(Guid accountId, string role, CancellationToken cancellationToken) =>
        (await repository.AccountById(accountId, cancellationToken)).Roles.Contains(role);

    /// <inheritdoc />
    public Task<Account> SetAccountStatus(SetAccountStatusInput input, CancellationToken cancellationToken) =>
        mediator.Send(new SetAccountStatusCommand(input), cancellationToken);

    /// <inheritdoc />
    public Task SendPhoneCode(string phone, string purpose, CancellationToken cancellationToken) =>
        // No client IP: the merchant's request already passed the per-user limits, and the
        // per-phone windows still apply to the contact's number.
        codes.Send(phone, purpose, null, cancellationToken);

    /// <inheritdoc />
    public Task CheckPhoneCode(string phone, string purpose, string code, CancellationToken cancellationToken) =>
        codes.CheckTyped(phone, purpose, code);
}
