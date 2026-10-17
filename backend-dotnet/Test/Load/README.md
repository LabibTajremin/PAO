# Load tests

The k6 scripts (`test/perf/` at the repository root) move here at cut-over (P17 task 8)
and run against the .NET stack with the same thresholds: nearby search p95 < 300 ms, a
request reaches the merchant in < 3 s (PRD §11).
