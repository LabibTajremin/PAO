// Package app assembles the running system from configuration: infrastructure clients,
// modules and the HTTP handler. cmd/api and cmd/worker stay a few lines long.
package app

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/metrics"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/storage"
)

// Infra holds the shared infrastructure every module receives.
type Infra struct {
	Config  config.Config
	Log     *slog.Logger
	Pool    *pgxpool.Pool
	Redis   *redis.Client
	Storage *storage.Store
	Keys    redisx.Keys
	Clock   clock.Clock
	IDs     idgen.Generator
	Metrics *metrics.Metrics
}

// Connect opens the database and Redis and prepares the storage buckets.
func Connect(ctx context.Context, cfg config.Config, log *slog.Logger) (*Infra, error) {
	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return nil, err
	}
	rdb, err := redisx.Connect(ctx, cfg.RedisURL)
	if err != nil {
		pool.Close()
		return nil, err
	}
	store := storage.New(storage.Config{
		Endpoint: cfg.S3.Endpoint, PublicEndpoint: cfg.S3.PublicEndpoint, Region: cfg.S3.Region,
		AccessKey: cfg.S3.AccessKey, SecretKey: cfg.S3.SecretKey,
	})
	for _, bucket := range []string{cfg.S3.BucketPrivate, cfg.S3.BucketPublic} {
		if err := store.EnsureBucket(ctx, bucket); err != nil {
			pool.Close()
			_ = rdb.Close()
			return nil, fmt.Errorf("prepare storage: %w", err)
		}
	}
	return &Infra{
		Config: cfg, Log: log, Pool: pool, Redis: rdb, Storage: store,
		Keys: redisx.NewKeys(cfg.AppEnv), Clock: clock.System{}, IDs: idgen.V7{}, Metrics: metrics.New(),
	}, nil
}

// Close releases the connections.
func (i *Infra) Close() {
	i.Pool.Close()
	_ = i.Redis.Close()
}
