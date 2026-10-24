# Load tests

k6 scripts run by `./pao perf` against the local Docker stack, or by `./pao perf e2e`
against a fresh end-to-end stack (the push gate, `./pao ci`).

- `nearby.js` — nearby provider search at 50 requests a second, p95 < 300 ms with 2,000
  online providers. `./pao perf` first runs `migrate perf-seed 2000`, which writes
  verified, online electricians around Dhaka plus customer tokens to a fixture file
  (`out/perf-fixture.json`, never in production), then runs k6 with `FIXTURE` pointing at it.

Each customer token has its own rate-limit budget (120 requests per operation per
minute), so the fixture carries 50 of them.

The other PRD §11 threshold — a booking request reaches the merchant's phone in under
3 s — is measured by the latency journey (`Test/PAO.E2ETests/Journeys/LatencyJourney.cs`).
