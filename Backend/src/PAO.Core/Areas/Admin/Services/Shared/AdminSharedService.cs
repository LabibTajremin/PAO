using PAO.Core.Areas.Admin.Repositories;
using PAO.Lib.Areas.Admin;

namespace PAO.Core.Areas.Admin.Services.Shared;

/// <summary>The Admin contract for the other areas: Booking, Customer, Merchant and Verification read the settings here.</summary>
public sealed class AdminSharedService(SettingValues settings, ComplaintRepository complaints) : IAdminSharedService
{
    /// <inheritdoc />
    public Task<PlatformSettings> GetSettings(CancellationToken cancellationToken) => settings.Typed(cancellationToken);

    /// <inheritdoc />
    public Task<int> CountVerifiedComplaints(Guid againstId, CancellationToken cancellationToken) => complaints.CountVerified(againstId, cancellationToken);
}
