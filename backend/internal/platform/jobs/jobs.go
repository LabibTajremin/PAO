// Package jobs wraps River, the Postgres-backed job queue (ADR-0006): modules register
// workers and periodic jobs; the API enqueues inside its transactions and the worker
// process runs them (docs/build/02-architecture.md §9).
package jobs

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
)

// Registry collects every module's workers and schedules before the client starts.
type Registry struct {
	workers  *river.Workers
	periodic []*river.PeriodicJob
}

// NewRegistry returns an empty registry.
func NewRegistry() *Registry { return &Registry{workers: river.NewWorkers()} }

// Register adds a worker for job arguments of type T.
func Register[T river.JobArgs](r *Registry, w river.Worker[T]) {
	river.AddWorker(r.workers, w)
}

// Every schedules args to be enqueued on a fixed interval.
func (r *Registry) Every(interval time.Duration, args river.JobArgs) {
	r.periodic = append(r.periodic, river.NewPeriodicJob(river.PeriodicInterval(interval), fixedArgs(args), nil))
}

// Daily schedules args once a day at hour:minute Asia/Dhaka (e.g. expiry at 02:00).
func (r *Registry) Daily(hour, minute int, args river.JobArgs) {
	r.periodic = append(r.periodic, river.NewPeriodicJob(dailyAt{hour: hour, minute: minute}, fixedArgs(args), nil))
}

func fixedArgs(args river.JobArgs) river.PeriodicJobConstructor {
	return func() (river.JobArgs, *river.InsertOpts) { return args, nil }
}

// dailyAt is a river.PeriodicSchedule firing at a fixed Dhaka wall-clock time.
type dailyAt struct{ hour, minute int }

func (d dailyAt) Next(current time.Time) time.Time {
	local := current.In(clock.Dhaka)
	next := time.Date(local.Year(), local.Month(), local.Day(), d.hour, d.minute, 0, 0, clock.Dhaka)
	if !next.After(local) {
		next = next.AddDate(0, 0, 1)
	}
	return next.UTC()
}

// Client is the River client the application uses.
type Client = river.Client[pgx.Tx]

// NewClient returns the River client. With a nil registry it can only enqueue (the API
// process); otherwise it runs the registry's workers and schedules with up to
// maxWorkers concurrent jobs (the worker process).
func NewClient(pool *pgxpool.Pool, r *Registry, maxWorkers int, log *slog.Logger) (*Client, error) {
	cfg := &river.Config{Logger: log}
	if r != nil {
		cfg.Queues = map[string]river.QueueConfig{river.QueueDefault: {MaxWorkers: maxWorkers}}
		cfg.Workers, cfg.PeriodicJobs = r.workers, r.periodic
	}
	c, err := river.NewClient(riverpgxv5.New(pool), cfg)
	if err != nil {
		return nil, fmt.Errorf("river client: %w", err)
	}
	return c, nil
}

// Migrate applies River's own schema migrations.
func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	m, err := rivermigrate.New(riverpgxv5.New(pool), nil)
	if err == nil {
		_, err = m.Migrate(ctx, rivermigrate.DirectionUp, nil)
	}
	if err != nil {
		return fmt.Errorf("river migrate: %w", err)
	}
	return nil
}
