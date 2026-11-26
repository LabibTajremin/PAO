# PAO.E2ETests

Two kinds of black-box test: start-up smoke tests that launch the real hosts, and full API journeys (`Category=Journey`) against the e2e stack.

The journeys need `infra/e2e/stack.sh`; the smoke tests only need a build.

## Run it

```sh
cd Backend && dotnet test --project tests/PAO.E2ETests -- --filter-not-trait "Category=Journey"
```

## Open these first

- `StartupSmokeTests.cs`
- `Journeys/BookingJourney.cs`: book to rating, the main path
- `Support/`: the HTTP client and helpers
