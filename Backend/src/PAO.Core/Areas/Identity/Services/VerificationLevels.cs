using PAO.Core.Areas.Verification.Services.Shared;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>Asks the Verification area for a merchant's level, for the provider gate (PRD §8.5).</summary>
public interface ILevelReader
{
    /// <summary>The merchant's level.</summary>
    Task<int> GetLevel(Guid merchantId, CancellationToken cancellationToken);
}

/// <summary>
/// Reads levels through <see cref="IVerificationSharedService"/>, resolved on first use:
/// Verification depends on areas that depend on Identity, and it is ported later.
/// </summary>
public sealed class VerificationLevels(IServiceProvider services) : ILevelReader
{
    /// <inheritdoc />
    public Task<int> GetLevel(Guid merchantId, CancellationToken cancellationToken) =>
        services.GetRequiredService<IVerificationSharedService>().GetLevel(merchantId, cancellationToken);
}
