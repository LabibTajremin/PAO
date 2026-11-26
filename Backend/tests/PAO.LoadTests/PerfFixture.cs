using System.Text.Json;

namespace PAO.LoadTests;

/// <summary>What `migrate perf-seed` writes: customer tokens and a search around the seeded providers.</summary>
public sealed record PerfFixture(
    IReadOnlyList<string> Tokens,
    string ServiceId,
    string SubServiceId,
    double Lat,
    double Lng)
{
    private static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);

    /// <summary>Reads the fixture file; a fixture without tokens cannot drive any request.</summary>
    public static PerfFixture Load(string path)
    {
        var fixture = JsonSerializer.Deserialize<PerfFixture>(File.ReadAllText(path), Options)
            ?? throw new InvalidDataException($"{path} is empty");
        return fixture.Tokens.Count > 0 ? fixture : throw new InvalidDataException($"{path} has no tokens");
    }
}
