using System.Diagnostics;

namespace PAO.LoadTests;

/// <summary>How hard and how long a scenario runs: a constant number of starts per second.</summary>
public sealed record ArrivalPlan(int RatePerSecond, TimeSpan Duration, int MaxInFlight);

/// <summary>One request's outcome: its latency, whether it got an answer, and whether the answer checked out.</summary>
public sealed record Sample(TimeSpan Latency, bool Failed, bool Checked);

/// <summary>
/// Starts requests at a constant arrival rate, independent of how fast earlier ones answer,
/// so a slow server shows up as latency rather than as fewer requests.
/// </summary>
public static class ArrivalRateRunner
{
    public static async Task<IReadOnlyList<Sample>> Run(ArrivalPlan plan, Func<int, Task<Sample>> send)
    {
        var total = (int)(plan.RatePerSecond * plan.Duration.TotalSeconds);
        var interval = TimeSpan.FromSeconds(1.0 / plan.RatePerSecond);
        // Bounds open connections like a fixed pool of virtual users; a start that finds
        // the pool full waits, and that wait counts towards its latency.
        using var slots = new SemaphoreSlim(plan.MaxInFlight);
        var clock = Stopwatch.StartNew();
        var running = new List<Task<Sample>>(total);
        for (var i = 0; i < total; i++)
        {
            var due = interval * i;
            if (due > clock.Elapsed)
            {
                await Task.Delay(due - clock.Elapsed);
            }

            running.Add(Timed(slots, send, i));
        }

        return await Task.WhenAll(running);
    }

    private static async Task<Sample> Timed(SemaphoreSlim slots, Func<int, Task<Sample>> send, int iteration)
    {
        var watch = Stopwatch.StartNew();
        await slots.WaitAsync();
        try
        {
            var sample = await send(iteration);
            return sample with { Latency = watch.Elapsed };
        }
        catch (Exception e) when (e is HttpRequestException or TaskCanceledException)
        {
            return new Sample(watch.Elapsed, Failed: true, Checked: false);
        }
        finally
        {
            slots.Release();
        }
    }
}
