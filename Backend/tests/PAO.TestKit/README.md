# PAO.TestKit

Fakes and helpers shared by the test projects: a fake clock, in-memory adapters and throwaway databases.

If a test needs a stand-in for an external service, add it here so every test project can use it.

## Open these first

- `Fakes.cs`
- `TestDatabases.cs`: create a database with every script applied
- `TestEnvironment.cs`: reads the `PAO_TEST_*` settings
