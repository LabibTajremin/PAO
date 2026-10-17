# Migrations

- Format: goose (`-- +goose Up` / `Down`, `StatementBegin/End`, `NO TRANSACTION`), parsed by
  `GooseParser` exactly as the NestJS parser did.
- `GooseMigrator.Up` takes `pg_advisory_lock(7041998310)`, then per module creates
  `goose_<module>` in the goose v3 shape when missing (with the version-0 row), refuses
  out-of-order files, and applies each pending file in its own transaction, recording the
  version. A database migrated by NestJS (or Go) is therefore up to date here; the
  integration test `GooseMigratorTests` proves it with a database prepared the NestJS way.
- New scripts: add `NNNN_name.sql` to the module folder, list new modules in
  `modules.json`, and add the script to the [index](README.md).
- Run: `dotnet PAO.Migrator.dll up` (`/app/migrate up` in the image).
