using PAO.Lib.Areas.Media;

namespace PAO.Core.Areas.Media.Services;

/// <summary>What a purpose accepts; sensitive files are verification documents, audited on every view.</summary>
public sealed record UploadRule(IReadOnlyList<string> ContentTypes, long MaxBytes, bool Sensitive);

/// <summary>Who uploads: the customer app, the partner app, or an admin through other areas.</summary>
public enum Uploader
{
    /// <summary>The customer app.</summary>
    Customer,
    /// <summary>The partner app.</summary>
    Merchant,
    /// <summary>An admin, through another area (Level 2 photos).</summary>
    Admin,
}

/// <summary>The upload rules per purpose (PRD §6.6).</summary>
public static class MediaRules
{
    private const long Mb = 1 << 20;
    private static readonly string[] Images = ["image/jpeg", "image/png"];
    private static readonly string[] Documents = ["image/jpeg", "image/png", "application/pdf"];

    private static readonly Dictionary<string, UploadRule> Rules = new(StringComparer.Ordinal)
    {
        [MediaPurpose.Avatar] = new(Images, 2 * Mb, false),
        [MediaPurpose.ComplaintPhoto] = new(Images, 5 * Mb, false),
        [MediaPurpose.NidFront] = new(Images, 5 * Mb, true),
        [MediaPurpose.NidBack] = new(Images, 5 * Mb, true),
        [MediaPurpose.Selfie] = new(Images, 5 * Mb, true),
        [MediaPurpose.PoliceClearance] = new(Documents, 5 * Mb, true),
        [MediaPurpose.SkillProof] = new(Documents, 5 * Mb, true),
        [MediaPurpose.AddressProof] = new(Documents, 5 * Mb, true),
        [MediaPurpose.Level2Photo] = new(Images, 5 * Mb, true),
    };

    private static readonly Dictionary<Uploader, string[]> Uploads = new()
    {
        [Uploader.Customer] = [MediaPurpose.Avatar, MediaPurpose.ComplaintPhoto],
        [Uploader.Merchant] =
        [
            MediaPurpose.Avatar, MediaPurpose.ComplaintPhoto, MediaPurpose.NidFront, MediaPurpose.NidBack, MediaPurpose.Selfie,
            MediaPurpose.PoliceClearance, MediaPurpose.SkillProof, MediaPurpose.AddressProof,
        ],
        [Uploader.Admin] = [MediaPurpose.Level2Photo],
    };

    /// <summary>The rule of a purpose, if it is one.</summary>
    public static UploadRule? RuleFor(string purpose) => Rules.GetValueOrDefault(purpose);

    /// <summary>Reports whether files of `purpose` are verification documents.</summary>
    public static bool IsSensitive(string purpose) => RuleFor(purpose)?.Sensitive == true;

    /// <summary>Why an upload is refused, or null when it may go ahead.</summary>
    public static string? Refusal(Uploader uploader, string purpose, string contentType, long sizeBytes)
    {
        var rule = RuleFor(purpose);
        if (rule is null || !Uploads[uploader].Contains(purpose))
        {
            return MediaReasons.Forbidden;
        }
        var fits = sizeBytes >= 1 && sizeBytes <= rule.MaxBytes;
        return rule.ContentTypes.Contains(contentType) && fits ? null : MediaReasons.Invalid;
    }

    /// <summary>Places files by purpose and owner, so retention jobs can work per owner.</summary>
    public static string ObjectKey(string purpose, Guid ownerId, Guid id) => $"{purpose}/{ownerId}/{id}";
}
