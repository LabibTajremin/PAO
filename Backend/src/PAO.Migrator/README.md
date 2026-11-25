# PAO.Migrator

The database tool: applies the SQL in `database/changes`, loads seed data and does one-off maintenance.

Commands: `up`, `seed`, `bundle`, `perf-seed N`, `create-admin`, `reencrypt`, `import-places FILE` (Dhaka places from OpenStreetMap, ADR-0042). EF never creates schema; these scripts own it.

## Run it

```sh
cd Backend && dotnet run --project src/PAO.Migrator -- up
```

## Open these first

- `MigratorCommand.cs`: the command list
- `SeedCommand.cs` and `SeedFile.cs`: how `database/seed/catalog.yaml` gets loaded
- `SchemaBundle.cs`: the single-file `bundle/schema.sql`
