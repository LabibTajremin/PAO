# test/backend/integration

Go integration tests live beside the code they cover (`*_integration_test.go`, build tag
`integration`), because Go does not allow importing `backend/internal/...` from here.
See [ADR-0008](../../../docs/adr/0008-run-go-integration-tests-against-provided-service-endpoints.md).
Run them with `./pao test integration`.
