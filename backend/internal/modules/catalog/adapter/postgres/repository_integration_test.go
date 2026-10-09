//go:build integration

package postgres_test

import (
	"context"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

// TestTree_ReportsEachQueryFailure breaks one table at a time in a private database.
func TestTree_ReportsEachQueryFailure(t *testing.T) {
	for _, table := range []string{"catalog.categories", "catalog.services", "catalog.sub_services"} {
		ctx := context.Background()
		pool, err := db.Connect(ctx, testkit.MigratedDatabase(t))
		if err != nil {
			t.Fatal(err)
		}
		clk := clock.NewFake(time.Now())
		repo := postgres.New(pool, outbox.NewWriter("catalog", idgen.V7{}, clk), clk)
		if _, err := pool.Exec(ctx, "ALTER TABLE "+table+" RENAME TO broken"); err != nil {
			t.Fatal(err)
		}
		if _, err := repo.Tree(ctx); err == nil {
			t.Errorf("tree with %s missing succeeded", table)
		}
		pool.Close()
	}
}
