# backend-nest/migrations

goose-format SQL migrations, one folder and one Postgres schema per module. The files
are byte-for-byte copies of `backend/migrations/<module>/`, so the Go and NestJS
backends run against the same database (ADR-0032); change both until the Go backend is
deleted.

- `modules.json` is the single source of truth for the module order (`modules`) and
  for the modules that publish events and so own an outbox table (`outboxModules`;
  audit and notification only consume). The migrator (`migrate up`) and the outbox
  relay read it.
- Each module keeps its own version table, `goose_<module>`, so a module's schema can
  later move to its own database unchanged. Modules share no foreign keys (PRD §9.3
  rule 3), so the order only matters for readability.
- The migrator applies the `-- +goose Up` section of each pending file; the
  `-- +goose Down` section rolls a module back to version zero in tests.
- sqlc reads each module folder as that module's schema (`sqlc.yaml`), so the typed
  query functions see a new migration after `npm run gen`.
