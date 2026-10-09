// Package testkit provides integration-test infrastructure: a private Postgres database
// per test, Redis key isolation and S3 settings (ADR-0008). It is test support code and
// is excluded from the coverage gate.
package testkit

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	_ "github.com/jackc/pgx/v5/stdlib" // registers the "pgx" database/sql driver

	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/migrations"
)

// Env returns a required PAO_TEST_* variable or fails the test: integration tests never
// skip silently (03-testing.md).
func Env(t testing.TB, name string) string {
	t.Helper()
	v := os.Getenv(name)
	if v == "" {
		t.Fatalf("%s is not set; run ./pao test integration", name)
	}
	return v
}

// EmptyDatabase creates a fresh, empty database and returns its URL. It is dropped when
// the test ends.
func EmptyDatabase(t testing.TB) string {
	t.Helper()
	return createDatabase(t, "")
}

// MigratedDatabase returns the URL of a fresh database with every migration applied,
// cloned from a template built once per migration set.
func MigratedDatabase(t testing.TB) string {
	t.Helper()
	return createDatabase(t, ensureTemplate(t))
}

func adminDB(t testing.TB) *sql.DB {
	t.Helper()
	conn, err := sql.Open("pgx", Env(t, "PAO_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatalf("open admin connection: %v", err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	return conn
}

func createDatabase(t testing.TB, template string) string {
	t.Helper()
	admin := adminDB(t)
	name := "pao_test_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	stmt := "CREATE DATABASE " + name
	if template != "" {
		stmt += " TEMPLATE " + template
	}
	if _, err := admin.ExecContext(context.Background(), stmt); err != nil {
		t.Fatalf("create database: %v", err)
	}
	t.Cleanup(func() {
		_, _ = admin.ExecContext(context.Background(), "DROP DATABASE IF EXISTS "+name+" WITH (FORCE)")
	})
	return withDatabase(t, Env(t, "PAO_TEST_DATABASE_URL"), name)
}

// ensureTemplate builds the migrated template database once per migration content;
// an advisory lock serialises parallel test packages.
func ensureTemplate(t testing.TB) string {
	t.Helper()
	ctx := context.Background()
	name := "pao_tpl_" + migrationsHash(t)
	admin := adminDB(t)
	conn, err := admin.Conn(ctx)
	if err != nil {
		t.Fatalf("admin conn: %v", err)
	}
	defer func() { _ = conn.Close() }()
	if _, err := conn.ExecContext(ctx, "SELECT pg_advisory_lock(424242)"); err != nil {
		t.Fatalf("lock: %v", err)
	}
	defer func() { _, _ = conn.ExecContext(ctx, "SELECT pg_advisory_unlock(424242)") }()
	var exists bool
	if err := conn.QueryRowContext(ctx, "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = $1)", name).Scan(&exists); err != nil {
		t.Fatalf("check template: %v", err)
	}
	if !exists {
		buildTemplate(t, conn, name)
	}
	return name
}

func buildTemplate(t testing.TB, conn *sql.Conn, name string) {
	t.Helper()
	ctx := context.Background()
	if _, err := conn.ExecContext(ctx, "CREATE DATABASE "+name); err != nil {
		t.Fatalf("create template: %v", err)
	}
	tpl, err := sql.Open("pgx", withDatabase(t, Env(t, "PAO_TEST_DATABASE_URL"), name))
	if err != nil {
		t.Fatalf("open template: %v", err)
	}
	defer func() { _ = tpl.Close() }()
	err = db.NewMigrator(tpl, migrations.FS, migrations.Modules).Up(ctx)
	if err == nil {
		err = migrateRiver(ctx, withDatabase(t, Env(t, "PAO_TEST_DATABASE_URL"), name))
	}
	if err != nil {
		_, _ = conn.ExecContext(ctx, "DROP DATABASE IF EXISTS "+name+" WITH (FORCE)")
		t.Fatalf("migrate template: %v", err)
	}
}

func migrationsHash(t testing.TB) string {
	t.Helper()
	h := sha256.New()
	_, _ = h.Write([]byte("river:v0.49.0\n"))
	err := fs.WalkDir(migrations.FS, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}
		b, err := fs.ReadFile(migrations.FS, path)
		if err != nil {
			return err
		}
		_, _ = fmt.Fprintf(h, "%s\n%s\n", path, b)
		return nil
	})
	if err != nil {
		t.Fatalf("hash migrations: %v", err)
	}
	return hex.EncodeToString(h.Sum(nil))[:16]
}

func withDatabase(t testing.TB, raw, name string) string {
	t.Helper()
	u, err := url.Parse(raw)
	if err != nil {
		t.Fatalf("parse database url: %v", err)
	}
	u.Path = "/" + name
	return u.String()
}

func migrateRiver(ctx context.Context, url string) error {
	pool, err := db.Connect(ctx, url)
	if err != nil {
		return err
	}
	defer pool.Close()
	return jobs.Migrate(ctx, pool)
}
