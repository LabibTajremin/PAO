using System.Globalization;

namespace PAO.LoadTests;

/// <summary>The pass marks of a scenario.</summary>
public sealed record Thresholds(TimeSpan P95, double MaxFailureRate, double MinCheckRate);

/// <summary>Latency percentiles and failure and check rates over a run's samples.</summary>
public sealed record LoadReport(int Requests, TimeSpan P50, TimeSpan P95, TimeSpan Max, double FailureRate, double CheckRate)
{
    public static LoadReport From(IReadOnlyList<Sample> samples)
    {
        var sorted = samples.Select(s => s.Latency).Order().ToArray();
        return new LoadReport(
            samples.Count,
            Percentile(sorted, 0.50),
            Percentile(sorted, 0.95),
            sorted.Length == 0 ? TimeSpan.Zero : sorted[^1],
            Rate(samples, s => s.Failed),
            Rate(samples, s => s.Checked));
    }

    /// <summary>A line per threshold the run missed; none when it passed.</summary>
    public IEnumerable<string> Missed(Thresholds limits)
    {
        if (Requests == 0)
        {
            yield return "no requests were made";
        }

        if (P95 >= limits.P95)
        {
            yield return $"p95 {Ms(P95)} >= {Ms(limits.P95)}";
        }

        if (FailureRate > limits.MaxFailureRate)
        {
            yield return $"failures {FailureRate:P2} > {limits.MaxFailureRate:P2}";
        }

        if (CheckRate < limits.MinCheckRate)
        {
            yield return $"checks {CheckRate:P2} < {limits.MinCheckRate:P2}";
        }
    }

    public override string ToString() => string.Create(
        CultureInfo.InvariantCulture,
        $"{Requests} requests, p50 {Ms(P50)}, p95 {Ms(P95)}, max {Ms(Max)}, failures {FailureRate:P2}, checks {CheckRate:P2}");

    // Nearest-rank percentile, the definition most load tools report.
    private static TimeSpan Percentile(TimeSpan[] sorted, double p) =>
        sorted.Length == 0 ? TimeSpan.Zero : sorted[Math.Max(0, (int)Math.Ceiling(p * sorted.Length) - 1)];

    private static double Rate(IReadOnlyList<Sample> samples, Func<Sample, bool> hit) =>
        samples.Count == 0 ? 0 : samples.Count(hit) / (double)samples.Count;

    private static string Ms(TimeSpan t) => string.Create(CultureInfo.InvariantCulture, $"{t.TotalMilliseconds:F1} ms");
}
