using PAO.LoadTests;

// Usage: PAO.LoadTests <base-url> <fixture.json>; exits 1 when a threshold is missed.
if (args.Length != 2)
{
    await Console.Error.WriteLineAsync("usage: PAO.LoadTests <base-url> <fixture.json>");
    return 2;
}

var fixture = PerfFixture.Load(args[1]);
using var http = new HttpClient { BaseAddress = new Uri(args[0]), Timeout = TimeSpan.FromSeconds(10) };
// A fresh stack JIT-compiles and fills its pools on the first requests; the thresholds are
// about steady-state search, so a short warm-up at the same rate is reported but not judged.
var warmUp = await ArrivalRateRunner.Run(NearbySearch.WarmUp, i => NearbySearch.Send(http, fixture, i));
Console.WriteLine($"nearby warm-up: {LoadReport.From(warmUp)}");
var samples = await ArrivalRateRunner.Run(NearbySearch.Plan, i => NearbySearch.Send(http, fixture, warmUp.Count + i));
var report = LoadReport.From(samples);
Console.WriteLine($"nearby: {report}");
var missed = report.Missed(NearbySearch.Thresholds).ToList();
missed.ForEach(m => Console.Error.WriteLine($"nearby: threshold missed: {m}"));
return missed.Count == 0 ? 0 : 1;
