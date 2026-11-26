using FluentValidation;
using PAO.Core.Areas.Merchant.Services;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Features.Profile.Commands;

/// <summary>Changes the merchant's bio, photo and language (M28).</summary>
public sealed record UpdateMerchantProfile(Guid MerchantId, MerchantProfileInput Input) : ICommand<MerchantProfileView>;

/// <summary>A bio of at most 500 characters and a supported language, as `provider.invalid`.</summary>
public sealed class UpdateMerchantProfileValidator : AbstractValidator<UpdateMerchantProfile>
{
    /// <summary>Declares the rule.</summary>
    public UpdateMerchantProfileValidator() => RuleFor(r => r.Input).Custom((input, _) =>
    {
        if (EnrolmentRules.Length(input.Bio ?? string.Empty) > 500 || input.Language is not (Language.English or Language.Bangla))
        {
            throw new DomainException(MerchantReasons.Invalid);
        }
    });
}

/// <summary>Answers <see cref="UpdateMerchantProfile"/>; a photo must be the merchant's own confirmed avatar.</summary>
public sealed class UpdateMerchantProfileHandler(MerchantProfiles profiles, MerchantPeers peers, MerchantViewsBuilder views)
    : IRequestHandler<UpdateMerchantProfile, MerchantProfileView>
{
    /// <inheritdoc />
    public async Task<MerchantProfileView> Handle(UpdateMerchantProfile request, CancellationToken cancellationToken)
    {
        var (id, input) = (request.MerchantId, request.Input);
        await profiles.Update(id, null, async m =>
        {
            if (input.PhotoMediaId is { } photo)
            {
                await peers.AttachAvatar(id, photo, cancellationToken);
            }
            return m with { Bio = input.Bio ?? string.Empty, PhotoMediaId = input.PhotoMediaId, Language = input.Language };
        }, cancellationToken);
        return await views.Own(id, cancellationToken);
    }
}
