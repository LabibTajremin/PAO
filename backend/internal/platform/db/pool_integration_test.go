//go:build integration

package db_test

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestWithTx_CommitsAndRollsBack(t *testing.T) {
	ctx := context.Background()
	pool, err := db.Connect(ctx, testkit.EmptyDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if _, err := pool.Exec(ctx, "CREATE TABLE t (v int)"); err != nil {
		t.Fatal(err)
	}
	insert := func(tx pgx.Tx) error { _, err := tx.Exec(ctx, "INSERT INTO t VALUES (1)"); return err }
	if err := db.WithTx(ctx, pool, insert); err != nil {
		t.Fatal(err)
	}
	boom := errors.New("boom")
	if err := db.WithTx(ctx, pool, func(tx pgx.Tx) error { _ = insert(tx); return boom }); !errors.Is(err, boom) {
		t.Fatalf("err = %v", err)
	}
	err = db.WithTx(ctx, pool, func(tx pgx.Tx) error {
		_, err := tx.Exec(ctx, "SET CONSTRAINTS ALL DEFERRED; CREATE TABLE u (v int UNIQUE DEFERRABLE INITIALLY DEFERRED); INSERT INTO u VALUES (1), (1)")
		return err
	})
	if err == nil {
		t.Fatal("deferred violation did not fail the commit")
	}
	var n int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM t").Scan(&n); err != nil || n != 1 {
		t.Fatalf("rows = %d, err = %v", n, err)
	}
}

func TestConnect_FailsWhenDatabaseUnreachable(t *testing.T) {
	if _, err := db.Connect(context.Background(), "postgres://pao:pao@127.0.0.1:1/pao?connect_timeout=1"); err == nil {
		t.Fatal("connected to nothing")
	}
}
