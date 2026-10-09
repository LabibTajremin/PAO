package db

import (
	"context"
	"errors"
	"fmt"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func TestConnect_RejectsInvalidURL(t *testing.T) {
	if _, err := Connect(context.Background(), "postgres://%zz"); err == nil {
		t.Fatal("invalid url accepted")
	}
}

type failingBeginner struct{}

func (failingBeginner) Begin(context.Context) (pgx.Tx, error) {
	return nil, errors.New("no connection")
}

func TestWithTx_ReportsBeginFailure(t *testing.T) {
	err := WithTx(context.Background(), failingBeginner{}, func(pgx.Tx) error { return nil })
	if err == nil {
		t.Fatal("begin failure swallowed")
	}
}

func TestIsUniqueViolation(t *testing.T) {
	dup := fmt.Errorf("insert: %w", &pgconn.PgError{Code: "23505", ConstraintName: "uq"})
	cases := []struct {
		err        error
		constraint string
		want       bool
	}{
		{dup, "", true},
		{dup, "uq", true},
		{dup, "other", false},
		{&pgconn.PgError{Code: "23503"}, "", false},
		{errors.New("plain"), "", false},
	}
	for _, c := range cases {
		if got := IsUniqueViolation(c.err, c.constraint); got != c.want {
			t.Errorf("IsUniqueViolation(%v, %q) = %v", c.err, c.constraint, got)
		}
	}
}
