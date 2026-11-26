using System.Text.RegularExpressions;
using FluentValidation;

namespace PAO.Lib.Validation;

/// <summary>Rules shared by the areas' validators, with the spec's patterns.</summary>
public static partial class RuleExtensions
{
    /// <summary>A UUID in the form the spec's `format: uuid` accepts.</summary>
    public static IRuleBuilderOptions<T, string> Uuid<T>(this IRuleBuilder<T, string> rule) =>
        rule.Must(value => value is not null && UuidText().IsMatch(value)).WithMessage("{PropertyName} must be a UUID");

    /// <summary>A Bangladeshi mobile number as the spec's `Phone` schema accepts it.</summary>
    public static IRuleBuilderOptions<T, string> BangladeshPhone<T>(this IRuleBuilder<T, string> rule) =>
        rule.Matches(BdMobile()).WithMessage("{PropertyName} must be a Bangladeshi mobile number");

    /// <summary>Integer paisa: zero or more and within a JavaScript-safe integer (E9).</summary>
    public static IRuleBuilderOptions<T, long> Paisa<T>(this IRuleBuilder<T, long> rule) =>
        rule.InclusiveBetween(0, 9_007_199_254_740_991L);

    [GeneratedRegex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")]
    private static partial Regex UuidText();

    [GeneratedRegex(@"^(\+?880|0)?1[3-9][0-9]{8}$")]
    private static partial Regex BdMobile();
}
