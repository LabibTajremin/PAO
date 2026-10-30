using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.GetMe.Queries;

/// <summary>The signed-in account.</summary>
public sealed record GetMeQuery(Guid AccountId) : IQuery<AccountView>;

/// <summary>Validates <see cref="GetMeQuery"/>.</summary>
public sealed class GetMeValidator : AbstractValidator<GetMeQuery>
{
    /// <summary>The rules.</summary>
    public GetMeValidator() => RuleFor(q => q.AccountId).NotEmpty();
}

/// <summary>Handles <see cref="GetMeQuery"/>.</summary>
public sealed class GetMeHandler(IIdentityRepository repository, IMapper mapper) : IRequestHandler<GetMeQuery, AccountView>
{
    /// <inheritdoc />
    public async Task<AccountView> Handle(GetMeQuery request, CancellationToken cancellationToken) =>
        mapper.Map<AccountRecord, AccountView>(await repository.AccountById(request.AccountId, cancellationToken));
}
