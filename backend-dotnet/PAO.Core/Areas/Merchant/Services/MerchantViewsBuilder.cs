using System.Globalization;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>The merchant's own profile (M28) and the profile customers see (C11).</summary>
public sealed class MerchantViewsBuilder(MerchantProfiles profiles, MerchantPresence presence, MerchantPeers peers)
{
    /// <summary>The merchant's profile with presence, photo and service names, creating an empty one on first use.</summary>
    public async Task<MerchantProfileView> Own(Guid id, CancellationToken cancellationToken)
    {
        var m = await profiles.Load(id, cancellationToken);
        var online = await presence.IsAvailable(id);
        var (photoUrl, services) = await Shown(id, m, cancellationToken);
        return new MerchantProfileView
        {
            Id = m.Id,
            Name = m.FullName,
            Phone = m.Phone,
            PhotoUrl = photoUrl,
            Bio = m.Bio,
            Status = m.AccountStatus,
            Level = m.Level,
            Badge = MerchantRules.Badge(m.Level),
            Online = online,
            Language = m.Language,
            Services = services,
            ExperienceYears = m.ExperienceYears,
            HomeBase = m.HomeBase,
            WorkingRadiusM = m.HomeBase is null ? null : m.WorkingRadiusM,
            FlaggedForReview = m.Flagged,
        };
    }

    /// <summary>A verified, active merchant as customers see them; `provider.not_found` for anyone else.</summary>
    public async Task<MerchantPublicProfileView> Public(Guid viewer, Guid id, CancellationToken cancellationToken)
    {
        var m = await profiles.Get(id, cancellationToken);
        if (m.Level < 1 || m.AccountStatus != "active")
        {
            throw new DomainException(MerchantErrors.NotFound);
        }
        var (photoUrl, services) = await Shown(viewer, m, cancellationToken);
        var rating = await peers.Rating(id, cancellationToken);
        return new MerchantPublicProfileView
        {
            Id = m.Id,
            Name = m.FullName,
            PhotoUrl = photoUrl,
            Badge = MerchantRules.Badge(m.Level),
            Level = m.Level,
            Bio = m.Bio,
            ExperienceYears = m.ExperienceYears,
            Services = services,
            Rating = new RatingBreakdownView
            {
                Average = rating.Average,
                Count = rating.Count,
                Distribution = rating.Distribution.Select((n, i) => (Star: (i + 1).ToString(CultureInfo.InvariantCulture), n)).ToDictionary(x => x.Star, x => x.n),
            },
            CompletedJobs = m.CompletedJobs,
            MemberSince = m.CreatedAt.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture),
        };
    }

    /// <summary>The photo URL and service names every profile view shows; services come from the catalog's cached tree.</summary>
    private async Task<(string? PhotoUrl, IReadOnlyList<ServiceRefView> Services)> Shown(Guid viewer, StoredMerchant m, CancellationToken cancellationToken)
    {
        var url = m.PhotoMediaId is { } photo ? await peers.PhotoUrl(viewer, photo, cancellationToken) : null;
        var services = await peers.Services(m.ServiceIds, cancellationToken);
        return (url, [.. services.Select(s => new ServiceRefView { Id = s.Id, Name = s.Name })]);
    }
}
