using PAO.Lib.Areas.Admin;

namespace PAO.Core.Areas.Admin.Services.Shared;

/// <summary>
/// What other areas may ask of the Admin area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IAdminSharedService
{
    /// <summary>Returns the typed platform settings (A-10), defaults filled in.</summary>
    Task<PlatformSettings> GetSettings(CancellationToken cancellationToken);

    /// <summary>Returns verified complaints against a person; they feed the merchant quality review (PRD §6.4).</summary>
    Task<int> CountVerifiedComplaints(Guid againstId, CancellationToken cancellationToken);
}
