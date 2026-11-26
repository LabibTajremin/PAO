# PAO.UnitTests

Fast tests with no database or network: every rule, handler, mapper and guard, plus the architecture, size and docs gates (`Category=Gate`).

Tests use the fakes from `PAO.TestKit`.

## Run it

```sh
cd Backend && dotnet test --project tests/PAO.UnitTests
```

## Open these first

- `Architecture/`: the rules that keep areas apart and files small
- `Areas/`: tests per area, next to the code they cover
- `Infrastructure/`: config, push, crypto and friends
