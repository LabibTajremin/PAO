using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Core.Areas.Identity.Features.AdminUsers.Queries;
using PAO.Core.Areas.Identity.Features.RoleEditor.Commands;
using PAO.Core.Areas.Identity.Features.RoleEditor.Queries;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Controllers;

/// <summary>Admin users (A-10).</summary>
[ApiController]
[Area("Identity")]
[Route("v1/admin/admin-users")]
[ErrorMap(typeof(IdentityErrorMap))]
public sealed class AdminUsersController(IMediator mediator) : ControllerBase
{
    /// <summary>listAdminUsers.</summary>
    [HttpGet]
    [Admin(Permission = "admin_user:manage")]
    public Task<AdminUserListView> List() => mediator.Send(new ListAdminUsersQuery());

    /// <summary>inviteAdminUser.</summary>
    [HttpPost]
    [Admin(Permission = "admin_user:manage")]
    public async Task<IActionResult> Invite([FromBody] AdminUserInviteBody body) =>
        StatusCode(201, await mediator.Send(new InviteAdminUserCommand(body.Email, body.Name, body.Roles)));

    /// <summary>updateAdminUser: changes roles or deactivates, revoking sessions.</summary>
    [HttpPatch("{adminUserId}")]
    [Admin(Permission = "admin_user:manage")]
    public Task<AdminUserView> Update(Guid adminUserId, [FromBody] AdminUserUpdateBody body) =>
        mediator.Send(new UpdateAdminUserCommand(adminUserId, body.Roles, body.Active));
}

/// <summary>The role editor (A-10).</summary>
[ApiController]
[Area("Identity")]
[Route("v1/admin/roles")]
[ErrorMap(typeof(IdentityErrorMap))]
public sealed class RolesController(IMediator mediator) : ControllerBase
{
    /// <summary>listRoles.</summary>
    [HttpGet]
    [Admin(Permission = "role:manage")]
    public Task<RoleListView> List() => mediator.Send(new ListRolesQuery());

    /// <summary>updateRole: replaces the grants and bumps the RBAC version.</summary>
    [HttpPut("{role}")]
    [Admin(Permission = "role:manage")]
    public Task<RoleDefinitionView> Update(string role, [FromBody] RoleUpdateBody body) =>
        mediator.Send(new UpdateRoleCommand(role, body.Permissions, body.Screens));
}
