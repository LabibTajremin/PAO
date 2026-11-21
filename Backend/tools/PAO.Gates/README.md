# PAO.Gates

The checkers behind two of the gates: file and method size limits, and docs coverage (every area, feature, controller, job, config section and SQL script is documented; no broken links).

They run as part of the unit tests (`Category=Gate`) and in `./pao lint backend`.

## Run it

```sh
cd Backend && dotnet test --project tests/PAO.UnitTests -- --filter-trait "Category=Gate"
```

## Open these first

- `SizeChecker.cs`: 250 lines per file (400 in tests), 40 per method
- `DocsChecker.cs`: what has to be documented and where
- `../../tests/PAO.UnitTests/Architecture/GateTests.cs`: the gates' own tests
