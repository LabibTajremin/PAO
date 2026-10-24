using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.AdminUsers.Queries;

/// <summary>Every live admin, by email (A-10).</summary>
public sealed record ListAdminUsersQuery : IQuery<AdminUserListView>;

/// <summary>Validates <see cref="ListAdminUsersQuery"/>; it has no fields.</summary>
public sealed class ListAdminUsersValidator : AbstractValidator<ListAdminUsersQuery>;

/// <summary>Handles <see cref="ListAdminUsersQuery"/>.</summary>
public sealed class ListAdminUsersHandler(IIdentityRepository repository, IMapper mapper) : IRequestHandler<ListAdminUsersQuery, AdminUserListView>
{
    /// <inheritdoc />
    public async Task<AdminUserListView> Handle(ListAdminUsersQuery request, CancellationToken cancellationToken) =>
        new(mapper.MapAll<AdminRecord, AdminUserView>(await repository.ListAdmins(cancellationToken)));
}
