# P15 — Hardening & handover

**Goal:** the product is safe to launch and easy for the human team to take over.

**Read first:** PRD §10 (documentation), §11; `02-architecture.md` §7.

## Tasks

1. **Security review** — walk OWASP ASVS L2 and OWASP MASVS-L1; record each item as
   pass / fixed / accepted-risk in `docs/security-checklist.md`. Must pass: no secrets in
   repo or binaries (gitleaks, `strings` on APK), no high/critical findings from
   govulncheck, gosec, osv-scanner, trivy; rate limits verified; IDOR tests on every
   `:id` route; certificate pinning on release builds.
2. **Privacy** — verify PRD §6.6 and §11 rules with tests: documents never on customer
   APIs, every document view audited, address hidden before acceptance, location only
   while online, account deletion erases PII in every module; document-retention purge job.
3. **Operations** — `docs/runbooks/`: deploy, rollback, rotate JWT keys, restore database
   from backup (and a script that tests the restore), verification process (PRD §6 as an
   operations runbook → `docs/verification.md`), incident checklist.
4. **Observability** — dashboards-as-code (Grafana JSON) for latency, errors, booking
   funnel; alert rules for error rate and job failures; Sentry wired in all apps behind
   the error-reporting interface.
5. **Release builds** — Android App Bundles and iOS archives for both apps with flavours
   (dev/staging/prod); admin web production build; `docs/release.md` with signing steps
   (keys provided by the owner, never committed).
6. **Docs pass** — every module README current; `docs/architecture.md` includes "how to
   extract a module into a service" (PRD §10); `HANDOVER.md` with system overview, known
   limitations, the open ADRs needing owner review, and next steps (Phase 2 list).
7. **Final audit** — run `./pao ci` and `./pao perf` on a clean clone; attach results to
   the PR.

## Definition of done

All checklists complete, all gates green, PR merged, every phase in `PROGRESS.md` is
`done`. Reply "PAO build complete" and stop.
