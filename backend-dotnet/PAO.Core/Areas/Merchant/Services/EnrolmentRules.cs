using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>The enrolment wizard's rules (M05–M13, PRD §6.2).</summary>
public static class EnrolmentRules
{
    /// <summary>The wizard in order.</summary>
    public static readonly IReadOnlyList<string> Steps =
    [
        EnrolmentStep.Personal, EnrolmentStep.Services, EnrolmentStep.Area, EnrolmentStep.Nid, EnrolmentStep.Selfie,
        EnrolmentStep.PoliceClearance, EnrolmentStep.SkillProof, EnrolmentStep.EmergencyContact, EnrolmentStep.CodeOfConduct,
    ];

    /// <summary>
    /// Steps saved by this area and reported to Verification, which re-reviews the matching
    /// item (PRD §6.4: changed data is checked again).
    /// </summary>
    public static readonly IReadOnlyList<string> ProfileSteps =
        [EnrolmentStep.Personal, EnrolmentStep.Services, EnrolmentStep.Area, EnrolmentStep.EmergencyContact, EnrolmentStep.CodeOfConduct];

    /// <summary>Every step's status; skill proof is optional for Level 1 (PRD §6.2 item 7).</summary>
    public static EnrolmentStatus Progress(IReadOnlyCollection<string> done, bool submitted = false)
    {
        var steps = Steps.Select(s => new StepStatus { Step = s, Done = done.Contains(s), Required = s != EnrolmentStep.SkillProof }).ToList();
        return new EnrolmentStatus { Steps = steps, Complete = steps.All(s => s.Done || !s.Required), Submitted = submitted };
    }

    /// <summary>The wizard progress of a stored profile.</summary>
    public static EnrolmentStatus ProgressOf(StoredMerchant m) => Progress([.. m.StepsDone], m.SubmittedAt is not null);

    /// <summary>Adds a step to the done list once.</summary>
    public static IReadOnlyList<string> WithStep(IReadOnlyList<string> done, string step) => done.Contains(step) ? done : [.. done, step];

    /// <summary>Removes a step from the done list.</summary>
    public static IReadOnlyList<string> WithoutStep(IReadOnlyList<string> done, string step) => [.. done.Where(s => s != step)];

    /// <summary>The calendar date in Dhaka at `now`, which birthdays compare against (04-decisions E8).</summary>
    public static DateOnly DhakaDate(DateTimeOffset now) => DateOnly.FromDateTime(now.ToOffset(TimeSpan.FromHours(6)).DateTime);

    /// <summary>Checks the personal step; the merchant must be 18 on `today`. Null when fine.</summary>
    public static string? PersonalProblem(PersonalInfoInput p, DateOnly today)
    {
        var fits = Between(p.FullName, 3, 100) && Between(p.PresentAddress, 5, 300) && Between(p.PermanentAddress, 5, 300)
            && Length(p.Bio ?? string.Empty) <= 500 && p.Gender is Gender.Female or Gender.Male or Gender.Other;
        if (!fits)
        {
            return MerchantReasons.Invalid;
        }
        return p.DateOfBirth.AddYears(18) > today ? MerchantReasons.TooYoung : null;
    }

    /// <summary>The services step: one to five services and plausible experience.</summary>
    public static bool ServicesValid(int count, int experienceYears) => count is >= 1 and <= 5 && experienceYears is >= 0 and <= 60;

    /// <summary>The area step: a home base in Bangladesh and a 1–30 km radius.</summary>
    public static bool AreaValid(GeoPoint p, int radiusM) =>
        p.Lat is >= 20.5 and <= 26.7 && p.Lng is >= 88.0 and <= 92.7 && radiusM is >= 1000 and <= 30000;

    /// <summary>The emergency contact must be someone else's phone.</summary>
    public static bool ContactValid(EmergencyContact c, string ownPhone) =>
        Between(c.Name, 2, 80) && Between(c.Relation, 2, 40) && c.Phone.Length > 0 && c.Phone != ownPhone;

    /// <summary>Counts code points, as Go counted runes.</summary>
    public static int Length(string s) => s.EnumerateRunes().Count();

    private static bool Between(string s, int lo, int hi)
    {
        var n = Length(s.Trim());
        return n >= lo && n <= hi;
    }
}
