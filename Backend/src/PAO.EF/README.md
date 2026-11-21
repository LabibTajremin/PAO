# PAO.EF

The database model: `PaoDbContext`, one folder of entities and configurations per area.

It maps the tables the SQL in `database/changes` creates; it never migrates anything itself.

## Open these first

- `PaoDbContext.cs`
- `Schemas.cs`: which Postgres schema each area owns
- `Booking/`: an example of an area's entities and configurations
