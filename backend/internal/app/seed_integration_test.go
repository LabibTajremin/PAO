//go:build integration

package app_test

import (
	"context"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
	"github.com/LabibTajremin/PAO/backend/seed"
)

func TestSeed_CatalogAndDemoAdmins(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	cfg := a.Infra.Config
	cfg.AppEnv, cfg.SeedAdminPassword = config.EnvDev, "demo password 2026"
	for i := 0; i < 2; i++ {
		if err := app.Seed(ctx, a.Modules, cfg, seed.Catalog); err != nil {
			t.Fatal(err)
		}
	}
	r := a.Do(t, "POST", "/v1/auth/admin/login", map[string]string{"email": "verifier@pao.bd", "password": "demo password 2026"})
	if r.Status != 200 {
		t.Fatalf("seeded admin login: %d %s", r.Status, r.Body)
	}
	if err := app.Seed(ctx, a.Modules, cfg, []byte("categories: [")); err == nil {
		t.Fatal("broken yaml accepted")
	}
	bad := []byte("admins:\n  - {email: x@pao.bd, name: X, roles: [customer]}\n")
	if err := app.Seed(ctx, a.Modules, cfg, bad); err == nil {
		t.Fatal("customer role accepted for a demo admin")
	}
	cfg.AppEnv = config.EnvProd
	if err := app.Seed(ctx, a.Modules, cfg, bad); err != nil {
		t.Fatalf("production skips demo admins: %v", err)
	}
	a.Infra.Pool.Close()
	if err := app.Seed(ctx, a.Modules, cfg, seed.Catalog); err == nil {
		t.Fatal("seed on a closed pool succeeded")
	}
}
