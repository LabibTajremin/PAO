using System.Collections.Concurrent;
using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Media;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.IntegrationTests.Areas;

/// <summary>Merchants the Verification tests enrol; the Merchant area is ported in parallel.</summary>
public sealed class VerificationMerchants : IMerchantSharedService
{
    public ConcurrentDictionary<Guid, MerchantProfile> Profiles { get; } = new();

    public ConcurrentDictionary<Guid, List<string>> Steps { get; } = new();

    public HashSet<Guid> Incomplete { get; } = [];

    public MerchantProfile Add(Guid id, Guid service, bool full = true)
    {
        var p = new MerchantProfile
        {
            Id = id,
            FullName = "Rahim Uddin",
            DateOfBirth = full ? new DateOnly(1990, 1, 2) : null,
            Gender = "male",
            PresentAddress = "Road 1, Gulshan",
            PermanentAddress = "Village, Bogura",
            Phone = "+8801712345678",
            ServiceIds = [service],
            ExperienceYears = 3,
            HomeBase = full ? new GeoPoint { Lat = 23.79, Lng = 90.41 } : null,
            WorkingRadiusM = 5000,
            Language = "en",
            EmergencyContact = full ? new EmergencyContact { Name = "Karim", Relation = "Brother", Phone = "+8801812345678" } : null,
        };
        Profiles[id] = p;
        return p;
    }

    public Task<MerchantProfile> GetMerchant(Guid merchantId, CancellationToken cancellationToken) =>
        Profiles.TryGetValue(merchantId, out var p) ? Task.FromResult(p) : throw new DomainException(MerchantErrors.NotFound);

    public Task<IReadOnlyDictionary<Guid, MerchantProfile>> GetMerchants(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyDictionary<Guid, MerchantProfile>>(merchantIds.Where(Profiles.ContainsKey).ToDictionary(id => id, id => Profiles[id]));

    public Task<EnrolmentStatus> MarkStepDone(Guid merchantId, string step, CancellationToken cancellationToken)
    {
        var steps = Steps.GetOrAdd(merchantId, _ => []);
        lock (steps)
        {
            steps.Add(step);
            return Task.FromResult(new EnrolmentStatus { Steps = [.. steps.Select(s => new StepStatus { Step = s, Done = true, Required = s != "skill_proof" })], Complete = false, Submitted = false });
        }
    }

    public Task MarkSubmitted(Guid merchantId, CancellationToken cancellationToken) =>
        Incomplete.Contains(merchantId) ? throw new DomainException(MerchantErrors.EnrolmentIncomplete) : Task.CompletedTask;

    public Task<bool> IsAvailable(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<NearbyMerchant>> FindNearby(NearbyQuery query, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<EnrolmentStatus> Enrolment(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task ForceOffline(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<MerchantRecord>> SearchMerchants(MerchantQuery query, CancellationToken cancellationToken) => throw new NotSupportedException();
}

/// <summary>Uploads held in memory; one id fails as a storage outage would.</summary>
public sealed class VerificationMedia : IMediaSharedService
{
    public ConcurrentDictionary<Guid, MediaObject> Objects { get; } = new();

    public ConcurrentBag<Guid> Deleted { get; } = [];

    public ConcurrentBag<Guid> OwnersPurged { get; } = [];

    public Guid Broken { get; } = Guid.NewGuid();

    public Guid Add(Guid owner, string purpose, bool confirmed = true)
    {
        var id = Guid.NewGuid();
        Objects[id] = new MediaObject { Id = id, OwnerId = owner, Purpose = purpose, ContentType = "image/jpeg", SizeBytes = 10, Confirmed = confirmed };
        return id;
    }

    public Task<MediaObject> GetObject(Guid mediaId, CancellationToken cancellationToken) =>
        mediaId == Broken ? throw new InvalidOperationException("media down")
        : Objects.TryGetValue(mediaId, out var o) ? Task.FromResult(o) : throw new DomainException(MediaErrors.NotFound);

    public Task MarkAttached(Guid mediaId, CancellationToken cancellationToken) => Task.CompletedTask;

    public Task Delete(Guid mediaId, CancellationToken cancellationToken)
    {
        if (!Objects.TryRemove(mediaId, out _))
        {
            throw new DomainException(MediaErrors.NotFound);
        }
        Deleted.Add(mediaId);
        return Task.CompletedTask;
    }

    public Task DeleteOwnerFiles(Guid ownerId, CancellationToken cancellationToken)
    {
        OwnersPurged.Add(ownerId);
        return Task.CompletedTask;
    }

    public Task<UploadTicket> CreateUploadUrl(UploadRequest request, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<MediaObject> ConfirmUpload(Guid ownerId, Guid mediaId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<ViewUrl> GetViewUrl(ViewRequest request, CancellationToken cancellationToken) => throw new NotSupportedException();
}

/// <summary>Two services: an ordinary one and, unpublished, one that demands Level 2.</summary>
public sealed class VerificationCatalog : ICatalogSharedService
{
    public Guid Electrician { get; } = Guid.NewGuid();

    public Guid Gas { get; } = Guid.NewGuid();

    private CatalogService Service(Guid id, bool level2) => new()
    {
        Id = id,
        CategoryId = Guid.NewGuid(),
        Name = new Text { En = level2 ? "Gas" : "Electrician", Bn = "ইলেকট্রিশিয়ান" },
        Model = "fixed",
        RequiredLevel = 1,
        SearchRadiusM = 5000,
        WomenProvidersOnly = false,
        RequiresLevel2 = level2,
        Level2Checklist = [],
        Published = !level2,
    };

    public Task<CatalogService> GetService(Guid serviceId, CancellationToken cancellationToken) =>
        serviceId == Electrician || serviceId == Gas ? Task.FromResult(Service(serviceId, serviceId == Gas)) : throw new DomainException(CatalogErrors.ServiceNotFound);

    public Task<IReadOnlyList<CatalogService>> ListServices(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyList<CatalogService>>([Service(Electrician, false)]);

    public Task<PriceSnapshot> GetPriceSnapshot(Guid subServiceId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<PriceSnapshot>> GetPriceSnapshots(IReadOnlyCollection<Guid> subServiceIds, CancellationToken cancellationToken) => throw new NotSupportedException();
}

/// <summary>The platform defaults: clearances last a year, Level 2 cools off for 14 days, documents stay a year.</summary>
public sealed class VerificationSettingsFake : IAdminSharedService
{
    public Task<PlatformSettings> GetSettings(CancellationToken cancellationToken) => Task.FromResult(new PlatformSettings
    {
        AcceptTimeoutAsapMs = 1,
        AcceptTimeoutScheduledMs = 1,
        DefaultSearchRadiusM = 1,
        RatingFloor = 1,
        RatingMinJobs = 1,
        MaxProviderCancellations30d = 1,
        StartCodeMaxAttempts = 1,
        StartCodeLockoutMs = 1,
        ServiceAreaGeoJson = "{}",
        PoliceClearanceValidityMs = (long)TimeSpan.FromDays(365).TotalMilliseconds,
        Level2CoolingOffMs = (long)TimeSpan.FromDays(14).TotalMilliseconds,
        DocumentRetentionMs = (long)TimeSpan.FromDays(365).TotalMilliseconds,
    });

    public Task<int> CountVerifiedComplaints(Guid againstId, CancellationToken cancellationToken) => throw new NotSupportedException();
}
