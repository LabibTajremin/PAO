# ops — monitoring as code

| Path | What |
|---|---|
| `prometheus/prometheus.yml` | scrape config: jobs `pao-api` and `pao-worker` on `:9090/metrics` |
| `prometheus/rules/pao.yml` | recording and alert rules (error rate, latency, jobs, outbox) |
| `prometheus/tests/pao_test.yml` | `promtool test rules` cases for every alert |
| `grafana/dashboards/*.json` | PAO API, PAO worker (jobs and outbox), PAO booking funnel |
| `grafana/provisioning/` | file provisioning for the dashboards and the Prometheus datasource |

`./pao ops check` validates the config and rules, runs the rule tests (local `promtool`
or the pinned `quay.io/prometheus/prometheus` image) and checks that every dashboard
query uses only metrics the backend exports. CI runs it in the backend workflow.

## Metrics

Defined in `backend/src/platform/metrics`; both processes serve them on `METRICS_ADDR`.

| Metric | Labels | Source |
|---|---|---|
| `pao_http_requests_total` | route (OpenAPI template), method, status | API |
| `pao_http_request_duration_seconds` | route, method | API |
| `pao_job_runs_total` | name, outcome (`ok`, `failed`, `skipped`) | worker |
| `pao_job_duration_seconds` | name | worker |
| `pao_outbox_events_delivered_total` | module, event | worker |
| `pao_outbox_delivery_failures_total` | module, event, dead | worker |
| `pao_outbox_pending_events`, `pao_outbox_oldest_pending_seconds`, `pao_outbox_dead_events` | module | worker, read at scrape time |

Job names use the label `name` because Prometheus reserves `job` for the scrape target.
The booking funnel counts delivered `booking.*` events: each is counted once, when its
outbox row is marked published, so retries do not inflate it.

## Alerts

| Alert | Fires when | Severity |
|---|---|---|
| `PaoApiDown`, `PaoWorkerDown` | a target misses scrapes for 2 min | critical |
| `PaoApiHighErrorRate` | 5xx above 2% for 5 min | critical |
| `PaoApiElevatedErrorRate` | 5xx above 0.5% (the 99.5% budget) for 30 min | warning |
| `PaoNearbySearchSlow` | nearby search p95 above 300 ms for 15 min | warning |
| `PaoJobFailing` | a scheduled job failed in the last hour | warning |
| `PaoOutboxLagging` | an event has waited over a minute, for 5 min | critical |
| `PaoOutboxDeadLetters` | an event was dead-lettered | critical |

Route `critical` to the on-call phone and `warning` to the team channel in
Alertmanager (not part of this repository: receivers hold secrets). Every alert links
`docs/runbooks/incident-checklist.md`.

## Running it

Point Prometheus at `prometheus/prometheus.yml` with `rules/` beside it, replacing the
static targets with the production hosts. In Grafana, mount `grafana/dashboards` at
`/var/lib/grafana/dashboards`, `grafana/provisioning` at `/etc/grafana/provisioning` and
set `PAO_PROMETHEUS_URL`. Dashboards are read-only in Grafana: change the JSON here.

App crashes go to Sentry (one project per app) when the apps are built with
`--dart-define=PAO_SENTRY_DSN=…`; see `frontend/packages/pao_core/README.md`.
