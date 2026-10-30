using PAO.Core.Areas.Identity.Services;
using PAO.Core.Areas.Identity.Services.Shared;

namespace PAO.Core.Registration;

/// <summary>The Identity area's handlers, validators, services and shared contract.</summary>
public static class IdentityAreaRegistration
{
    /// <summary>
    /// Adds the Identity area's services and its `IIdentitySharedService`. Handlers and
    /// validators, and the mapping profile in PAO.Lib, are found by the mediator's scan. The repositories and Redis stores
    /// come from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddIdentityArea(this IServiceCollection services) => services
        .AddScoped<IAccessTokens, AccessTokens>()
        .AddScoped<IRbacGrants, RbacGrants>()
        .AddScoped<ILevelReader, VerificationLevels>()
        .AddScoped<PhoneCodes>()
        .AddScoped<PhoneAccounts>()
        .AddScoped<Sessions>()
        .AddScoped<AccountStatusChanger>()
        .AddScoped<AdminUsers>()
        .AddScoped<IIdentitySharedService, IdentitySharedService>();
}
