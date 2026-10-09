// Command migrate applies the module migrations and River's schema ("up") and loads
// seed data ("seed"). ./pao seed runs both.
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/stdlib"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/migrations"
	"github.com/LabibTajremin/PAO/backend/seed"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		logx.New(os.Stderr, 0).Error("migrate failed", "error", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) != 1 {
		return fmt.Errorf("usage: migrate up|seed")
	}
	switch args[0] {
	case "up":
		return up(context.Background())
	case "seed":
		return seedData(context.Background())
	}
	return fmt.Errorf("usage: migrate up|seed")
}

func up(ctx context.Context) error {
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

func seedData(ctx context.Context) error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	log := logx.New(os.Stdout, cfg.LogLevel)
	infra, err := app.Connect(ctx, cfg, log)
	if err != nil {
		return err
	}
	defer infra.Close()
	modules, err := app.BuildModules(infra)
	if err != nil {
		return err
	}
	return app.Seed(ctx, modules, cfg, seed.Catalog)
}
