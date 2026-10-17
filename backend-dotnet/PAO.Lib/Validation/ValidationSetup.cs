using System.Text.Json;
using FluentValidation;

namespace PAO.Lib.Validation;

/// <summary>
/// Global FluentValidation settings: property paths are reported in the JSON (camelCase)
/// names clients send, and a validator stops at its first failure per property, as the
/// spec validation stops at its first error.
/// </summary>
public static class ValidationSetup
{
    /// <summary>Applies the settings; idempotent.</summary>
    public static void Configure()
    {
        ValidatorOptions.Global.DefaultRuleLevelCascadeMode = CascadeMode.Stop;
        ValidatorOptions.Global.PropertyNameResolver = (_, member, _) => JsonName(member);
        ValidatorOptions.Global.DisplayNameResolver = (_, member, _) => JsonName(member);
    }

    private static string? JsonName(System.Reflection.MemberInfo? member) =>
        member is null ? null : JsonNamingPolicy.CamelCase.ConvertName(member.Name);
}
