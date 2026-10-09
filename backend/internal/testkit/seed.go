package testkit

import (
	"context"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/seed"
)

// SeedCatalog loads backend/seed/catalog.yaml into the test API's database.
func (a *API) SeedCatalog(t testing.TB) {
	t.Helper()
	cfg := a.Infra.Config
	cfg.SeedAdminPassword = ""
	if err := app.Seed(context.Background(), a.Modules, cfg, seed.Catalog); err != nil {
		t.Fatalf("seed: %v", err)
	}
}
