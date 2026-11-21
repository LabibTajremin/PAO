# Migrations

- Format: goose (`-- +goose Up` / `Down`, `StatementBegin/End`, `NO TRANSACTION`), parsed by
  `GooseParser` exactly as goose parses them.
- `GooseMigrator.Up` takes `pg_advisory_lock(7041998310)`, then per module creates
  `goose_<module>` in the goose v3 shape when missing (with the version-0 row), refuses
  out-of-order files, and applies each pending file in its own transaction, recording the
  version. A database migrated by an earlier release is therefore up to date here; the
  integration test `GooseMigratorTests` proves it with a database prepared the goose way.
- New scripts: add `NNNN_name.sql` to the module folder (never edit a script that has
  been applied anywhere; add a new one), list new modules in `modules.json`, add the
  script to the [index](README.md), its tables and indexes to [schema](schema.md), and
  regenerate the bundle (`scripts/gen-db-bundle.sh`).
- Run: `dotnet PAO.Migrator.dll up` (`/app/migrate up` in the image).
- Without the image: `bundle/schema.sql` applies the same scripts and version rows from a
  SQL editor ([bundle](README.md#single-file-scripts-bundle)).
