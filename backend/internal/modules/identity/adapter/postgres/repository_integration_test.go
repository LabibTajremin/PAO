//go:build integration

package postgres_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func newRepo(t *testing.T) *postgres.Repository {
	t.Helper()
	pool, err := db.Connect(context.Background(), testkit.MigratedDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	clk := clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))
	return postgres.New(pool, outbox.NewWriter("identity", idgen.V7{}, clk), clk)
}

func TestTxRepository_ReportsConstraintAndContextFailures(t *testing.T) {
	ctx := context.Background()
	r := newRepo(t)
	id := uuid.New()
	err := r.InTx(ctx, func(tx port.TxRepository) error {
		return tx.CreateAccount(ctx, domain.Account{ID: id, Phone: "+8801712345678", Status: domain.StatusActive, CreatedAt: time.Now()})
	})
	if err != nil {
		t.Fatal(err)
	}
	cancelled, cancel := context.WithCancel(ctx)
	cancel()
	failing := map[string]func(tx port.TxRepository) error{
		"unknown role":       func(tx port.TxRepository) error { return tx.SetRoles(ctx, id, []string{"pilot"}) },
		"revoke cancelled":   func(tx port.TxRepository) error { return tx.SetRoles(cancelled, id, nil) },
		"clear cancelled":    func(tx port.TxRepository) error { return tx.ReplaceRole(cancelled, "verifier", nil, nil) },
		"unknown permission": func(tx port.TxRepository) error { return tx.ReplaceRole(ctx, "verifier", []string{"made:up"}, nil) },
		"unknown screen":     func(tx port.TxRepository) error { return tx.ReplaceRole(ctx, "verifier", nil, []string{"Z99"}) },
	}
	for name, fn := range failing {
		if err := r.InTx(ctx, fn); err == nil {
			t.Errorf("%s: succeeded", name)
		}
	}
}

func TestRepository_ReadFailures(t *testing.T) {
	r := newRepo(t)
	cancelled, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := r.LoadGrants(cancelled, "customer"); err == nil {
		t.Error("grants")
	}
	if _, _, err := r.Catalogue(cancelled); err == nil {
		t.Error("catalogue")
	}
	if _, err := r.ListAdmins(cancelled); err == nil {
		t.Error("list admins")
	}
	if _, err := r.AdminByID(cancelled, uuid.New()); err == nil {
		t.Error("admin by id")
	}
}

func TestRepository_AdminWithoutCredentialsAndBrokenList(t *testing.T) {
	ctx := context.Background()
	r := newRepo(t)
	id := uuid.New()
	_ = r.InTx(ctx, func(tx port.TxRepository) error {
		return tx.CreateAccount(ctx, domain.Account{ID: id, Email: "a@pao.bd", Status: domain.StatusActive, CreatedAt: time.Now()})
	})
	if _, err := r.AdminByEmail(ctx, "a@pao.bd"); err != domain.ErrAccountNotFound {
		t.Fatalf("account without credentials: %v", err)
	}
	_ = r.InTx(ctx, func(tx port.TxRepository) error { return tx.CreateAdminCredentials(ctx, id, "h") })
	list, err := r.ListAdmins(ctx)
	if err != nil || len(list) != 1 {
		t.Fatalf("list: %v", err)
	}
}
