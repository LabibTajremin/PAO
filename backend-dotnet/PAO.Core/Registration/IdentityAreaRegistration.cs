using PAO.Core.Areas.Identity.Services;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;

namespace PAO.Core.Registration;

/// <summary>The Identity area's handlers, validators, services and shared contract.</summary>
public static class IdentityAreaRegistration
{
    /// <summary>
    /// Adds the Identity area's services and its `IIdentitySharedService`. Handlers and
    /// validators are found by the mediator's assembly scan; the mapping profile lives in
    /// PAO.Lib, outside that scan, so it is added here. The repositories and Redis stores
    /// come from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddIdentityArea(this IServiceCollection services) => services
        .AddSingleton<IMappingProfile, IdentityMappingProfile>()
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
