// Command migrate applies the module migrations and River's schema ("up"); later
// phases add "seed". ./pao seed runs it.
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/stdlib"

	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/migrations"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		logx.New(os.Stderr, 0).Error("migrate failed", "error", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) != 1 || args[0] != "up" {
		return fmt.Errorf("usage: migrate up")
	}
	ctx := context.Background()
	pool, err := db.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		return err
	}
	defer pool.Close()
	sqlDB := stdlib.OpenDBFromPool(pool)
	defer func() { _ = sqlDB.Close() }()
	if err := db.NewMigrator(sqlDB, migrations.FS, migrations.Modules).Up(ctx); err != nil {
		return err
	}
	return jobs.Migrate(ctx, pool)
}
