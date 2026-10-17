# PAO backend (.NET) documentation

The .NET backend of PAO (ADR-0034), built in `backend-dotnet/` and moved to `Backend/` at
cut-over. Every area, feature, controller, service, repository, job, config file and
script has a page or an index entry here; `DocsChecker` (`Tools/PAO.Gates`) fails the
gates when one is missing or a link is broken.

| Folder | What it covers |
|---|---|
| [Areas](Areas/README.md) | One folder per area: overview, features, endpoints, data, events |
| [Architecture](Architecture/README.md) | Projects, dependency rules, request flow, auth, events and jobs |
| [Config](Config/README.md) | Config files, sections and environment variables |
| [Database](Database/README.md) | The `DB Changes` scripts and the migrator |
| [Operations](Operations/README.md) | Hosts, Docker image, jobs, logging, metrics, health |
| [Testing](Testing/README.md) | Test projects, gates and coverage |
| [Api](Api/README.md) | The OpenAPI contract and the platform controllers |

Agent instructions for this backend live in [PAO.AI](../PAO.AI/README.md).
