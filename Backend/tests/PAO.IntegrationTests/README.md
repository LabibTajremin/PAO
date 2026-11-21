# PAO.IntegrationTests

Tests against real Postgres+PostGIS, Redis and S3: every repository, Redis adapter and HTTP endpoint, including each documented error.

They need the services from `./pao up` (or the `PAO_TEST_*` variables). Each test class gets its own database, Redis prefix and buckets.

## Run it

```sh
./pao up && cd Backend && dotnet test --project tests/PAO.IntegrationTests
```

## Open these first

- `Support.cs`: the shared fixture
- `ApiTests.cs`: the HTTP edge end to end
- `Areas/`: endpoint tests per area
