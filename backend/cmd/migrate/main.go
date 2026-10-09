// Command migrate applies the module migrations and River's schema ("up"), loads seed
// data ("seed") and prepares the performance smoke test ("perf-seed N", which prints
// the fixture JSON). ./pao seed runs up and seed; ./pao perf runs perf-seed.
package main

import (
	"context"
	"errors"
	"os"
	"strconv"

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

const usage = "usage: migrate up|seed|perf-seed N"

func run(args []string) error {
	switch {
	case len(args) == 1 && args[0] == "up":
		return up(context.Background())
	case len(args) == 1 && args[0] == "seed":
		return seedData(context.Background())
	case len(args) == 2 && args[0] == "perf-seed":
		n, err := strconv.Atoi(args[1])
		if err != nil || n < 1 {
			return errors.New(usage)
		}
		return perfSeed(context.Background(), n)
	}
	return errors.New(usage)
}

func perfSeed(ctx context.Context, n int) error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	infra, err := app.Connect(ctx, cfg, logx.New(os.Stderr, cfg.LogLevel))
	if err != nil {
		return err
	}
	defer infra.Close()
	modules, err := app.BuildModules(infra)
	if err != nil {
		return err
	}
	return app.SeedPerf(ctx, infra, modules, n, os.Stdout)
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
