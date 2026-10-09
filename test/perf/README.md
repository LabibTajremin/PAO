# test/perf

k6 performance scripts, run by `./pao perf` against the local Docker stack.

- `nearby.js` — nearby provider search, p95 < 300 ms with 2,000 online providers.
  `./pao perf` first runs `migrate perf-seed 2000`, which writes verified, online
  electricians around Dhaka plus customer tokens to a fixture file (never in
  production), then runs k6 with `FIXTURE` pointing at it.

Each customer token has its own rate-limit budget (120 requests per operation per
minute), so the fixture carries 50 of them.
