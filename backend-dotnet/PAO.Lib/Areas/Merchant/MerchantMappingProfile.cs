using PAO.EF.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Merchant;

/// <summary>A merchant row with the ids of the services it offers, loaded in the same round of queries.</summary>
public sealed record MerchantRow(MerchantProfileRecord Record, IReadOnlyList<Guid> ServiceIds);

/// <summary>The Merchant area's maps: rows to stored profiles, candidates and admin rows; profiles to contract DTOs.</summary>
public sealed class MerchantMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<MerchantRow, StoredMerchant>((row, _) => ToStored(row.Record, row.ServiceIds))
        .Add<StoredMerchant, MerchantProfile>((m, _) => new MerchantProfile
        {
            Id = m.Id,
            FullName = m.FullName,
            DateOfBirth = m.DateOfBirth,
            Gender = m.Gender,
            PresentAddress = m.PresentAddress,
            PermanentAddress = m.PermanentAddress,
            Phone = m.Phone,
            PhotoMediaId = m.PhotoMediaId,
            ServiceIds = m.ServiceIds,
            ExperienceYears = m.ExperienceYears,
            HomeBase = m.HomeBase,
            WorkingRadiusM = m.WorkingRadiusM,
            Language = m.Language,
            EmergencyContact = m.Emergency.Phone.Length == 0 ? null : m.Emergency,
            SubmittedAt = m.SubmittedAt,
        })
        .Add<MerchantProfileRecord, MerchantCandidate>((r, _) => new MerchantCandidate
        {
            Id = r.Id,
            Name = r.FullName,
            PhotoMediaId = r.PhotoMediaId,
            Gender = r.Gender ?? string.Empty,
            Level = r.Level,
            Rating = r.RatingAvg,
            RatingCount = r.RatingCount,
            CompletedJobs = r.CompletedJobs,
            DistanceM = 0,
            WorkingRadiusM = r.WorkingRadiusM,
        })
        .Add<MerchantRow, MerchantRecord>((row, _) => new MerchantRecord
        {
            Id = row.Record.Id,
            Name = row.Record.FullName,
            Phone = row.Record.Phone,
            Status = row.Record.AccountStatus == "active" && row.Record.Level == 0 ? "pending" : row.Record.AccountStatus,
            Level = row.Record.Level,
            ServiceIds = row.ServiceIds,
            Rating = row.Record.RatingAvg,
            RatingCount = row.Record.RatingCount,
            CompletedJobs = row.Record.CompletedJobs,
            Flagged = row.Record.FlaggedForReview,
            FlagReason = row.Record.FlagReason,
            Online = false,
            CreatedAt = row.Record.CreatedAt,
        });

    private static StoredMerchant ToStored(MerchantProfileRecord r, IReadOnlyList<Guid> serviceIds) => new()
    {
        Id = r.Id,
        Phone = r.Phone,
        FullName = r.FullName,
        DateOfBirth = r.DateOfBirth,
        Gender = r.Gender ?? string.Empty,
        PresentAddress = r.PresentAddress,
        PermanentAddress = r.PermanentAddress,
        Bio = r.Bio,
        PhotoMediaId = r.PhotoMediaId,
        ExperienceYears = r.ExperienceYears,
        Language = r.Language,
        ServiceIds = serviceIds,
        HomeBase = r.HomeBase is { } home ? new GeoPoint { Lat = home.Y, Lng = home.X } : null,
        WorkingRadiusM = r.WorkingRadiusM,
        Emergency = new EmergencyContact { Name = r.EmergencyName, Relation = r.EmergencyRelation, Phone = r.EmergencyPhone, VerifiedAt = r.EmergencyVerifiedAt },
        CocVersion = r.CocVersion,
        CocAcceptedAt = r.CocAcceptedAt,
        StepsDone = r.StepsDone,
        SubmittedAt = r.SubmittedAt,
        AccountStatus = r.AccountStatus,
        Level = r.Level,
        RatingAvg = r.RatingAvg,
        RatingCount = r.RatingCount,
        CompletedJobs = r.CompletedJobs,
        Flagged = r.FlaggedForReview,
        FlagReason = r.FlagReason,
        CreatedAt = r.CreatedAt,
    };
}
