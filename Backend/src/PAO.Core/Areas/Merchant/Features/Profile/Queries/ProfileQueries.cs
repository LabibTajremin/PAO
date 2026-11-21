using PAO.Core.Areas.Merchant.Services;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Features.Profile.Queries;

/// <summary>The merchant's own profile (M28); the first call creates an empty one.</summary>
public sealed record GetMerchantProfile(Guid MerchantId) : IQuery<MerchantProfileView>;

/// <summary>A verified, active merchant as a customer sees them (C11).</summary>
public sealed record GetMerchantPublicProfile(Guid ViewerId, Guid MerchantId) : IQuery<MerchantPublicProfileView>;

/// <summary>Answers <see cref="GetMerchantProfile"/>.</summary>
public sealed class GetMerchantProfileHandler(MerchantViewsBuilder views) : IRequestHandler<GetMerchantProfile, MerchantProfileView>
{
    /// <inheritdoc />
    public Task<MerchantProfileView> Handle(GetMerchantProfile request, CancellationToken cancellationToken) =>
        views.Own(request.MerchantId, cancellationToken);
}

/// <summary>Answers <see cref="GetMerchantPublicProfile"/>; never documents or contacts.</summary>
public sealed class GetMerchantPublicProfileHandler(MerchantViewsBuilder views) : IRequestHandler<GetMerchantPublicProfile, MerchantPublicProfileView>
{
    /// <inheritdoc />
    public Task<MerchantPublicProfileView> Handle(GetMerchantPublicProfile request, CancellationToken cancellationToken) =>
        views.Public(request.ViewerId, request.MerchantId, cancellationToken);
}
