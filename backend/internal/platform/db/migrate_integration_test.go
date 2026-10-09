//go:build integration

package db_test

import (
	"context"
	"database/sql"
	"testing"
	"testing/fstest"

	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
	"github.com/LabibTajremin/PAO/backend/migrations"
)

func TestMigrations_RoundTripUpDownUp(t *testing.T) {
	ctx := context.Background()
	conn, err := sql.Open("pgx", testkit.EmptyDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = conn.Close() }()
	m := db.NewMigrator(conn, migrations.FS, migrations.Modules)

	if err := m.Up(ctx); err != nil {
		t.Fatalf("first up: %v", err)
	}
	assertSchemas(t, conn, len(migrations.Modules))
	if err := m.Down(ctx); err != nil {
		t.Fatalf("down: %v", err)
	}
	assertSchemas(t, conn, 0)
	if err := m.Up(ctx); err != nil {
		t.Fatalf("second up: %v", err)
	}
	assertSchemas(t, conn, len(migrations.Modules))
}

func TestMigrations_UnknownModuleFails(t *testing.T) {
	conn, err := sql.Open("pgx", testkit.EmptyDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = conn.Close() }()
	m := db.NewMigrator(conn, migrations.FS, []string{"nope"})
	if err := m.Up(context.Background()); err == nil {
		t.Fatal("up with an unknown module succeeded")
	}
	if err := m.Down(context.Background()); err == nil {
		t.Fatal("down with an unknown module succeeded")
	}
}

func assertSchemas(t *testing.T, conn *sql.DB, want int) {
	t.Helper()
	var got int
	err := conn.QueryRow(`SELECT count(*) FROM information_schema.schemata WHERE schema_name = ANY($1)`,
		migrations.Modules).Scan(&got)
	if err != nil {
		t.Fatal(err)
	}
	if got != want {
		t.Fatalf("module schemas = %d, want %d", got, want)
	}
}

func TestMigrations_ReportsFailingStatements(t *testing.T) {
	conn, err := sql.Open("pgx", testkit.EmptyDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = conn.Close() }()
	ctx := context.Background()
	broken := fstest.MapFS{
		"bad_up/0001_x.sql":   {Data: []byte("-- +goose Up\nSELECT missing_column FROM nowhere;\n-- +goose Down\nSELECT 1;\n")},
		"bad_down/0001_x.sql": {Data: []byte("-- +goose Up\nSELECT 1;\n-- +goose Down\nSELECT missing_column FROM nowhere;\n")},
	}
	if err := db.NewMigrator(conn, broken, []string{"bad_up"}).Up(ctx); err == nil {
		t.Fatal("failing up migration reported success")
	}
	m := db.NewMigrator(conn, broken, []string{"bad_down"})
	if err := m.Up(ctx); err != nil {
		t.Fatalf("up: %v", err)
	}
	if err := m.Down(ctx); err == nil {
		t.Fatal("failing down migration reported success")
	}
	if err := db.NewMigrator(conn, broken, []string{"../escape"}).Up(ctx); err == nil {
		t.Fatal("invalid module path accepted")
	}
}
