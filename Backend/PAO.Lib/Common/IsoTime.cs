using System.Globalization;

namespace PAO.Lib.Common;

/// <summary>Timestamps in API answers, as JavaScript's `toISOString` wrote them for NestJS.</summary>
public static class IsoTime
{
    /// <summary>`2026-10-09T10:00:00.000Z`: UTC with milliseconds.</summary>
    public static string Format(DateTimeOffset at) =>
        at.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture);
}
