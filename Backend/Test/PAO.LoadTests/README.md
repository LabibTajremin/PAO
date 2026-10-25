# Load tests

`PAO.LoadTests` is a console app (plain `HttpClient`, no load-testing library) run by
`./pao perf` against the local Docker stack, or by `./pao perf e2e` against a fresh
end-to-end stack (the push gate, `./pao ci`):

    dotnet run --project Backend/Test/PAO.LoadTests -c Release -- <base-url> <fixture.json>

- `NearbySearch` — nearby provider search at a constant 50 requests a second for 30 s
  (at most 25 in flight, after a 5 s warm-up at the same rate that is reported but not
  judged, since a fresh stack JIT-compiles on its first requests) with 2,000 online providers. Thresholds: p95 < 300 ms, no failed
  requests, and every answer is 200 with at least one provider. `./pao perf` first runs
  `migrate perf-seed 2000`, which writes verified, online electricians around Dhaka plus
  customer tokens to a fixture file (`out/perf-fixture.json`, never in production).
- `ArrivalRateRunner` starts requests on schedule whatever earlier ones are doing, so a slow
  server shows as latency; `LoadReport` prints p50/p95/max and the failure and check
  rates, and the app exits 1 when a threshold is missed.

Each customer token has its own rate-limit budget (120 requests per operation per
minute), so the fixture carries 50 of them.

The other PRD §11 threshold — a booking request reaches the merchant's phone in under
3 s — is measured by the latency journey (`Test/PAO.E2ETests/Journeys/LatencyJourney.cs`).
