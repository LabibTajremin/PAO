// Command worker runs the outbox relay and scheduled background jobs. It ships in the
// same image as the API.
package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/health"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/migrations"
)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		if err := health.Probe(context.Background(), &http.Client{Timeout: 2 * time.Second}, "http://127.0.0.1:9090/healthz"); err != nil {
			os.Exit(1)
		}
		return
	}
	if err := run(); err != nil {
		logx.New(os.Stderr, 0).Error("worker stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	log := logx.New(os.Stdout, cfg.LogLevel)
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	infra, err := app.Connect(ctx, cfg, log)
	if err != nil {
		return err
	}
	defer infra.Close()

	bus := eventbus.NewBus()
	client, err := startJobs(ctx, infra)
	if err != nil {
		return err
	}
	relay, err := outbox.NewRelay(infra.Pool, bus, migrations.Modules, infra.Clock, log)
	if err != nil {
		return err
	}
	go relay.Run(ctx, 250*time.Millisecond)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", health.Liveness)
	mux.Handle("GET /metrics", infra.Metrics.Handler())
	ln, err := net.Listen("tcp", cfg.MetricsAddr)
	if err != nil {
		return err
	}
	log.Info("worker started")
	err = httpx.Runner{Server: httpx.NewServer("", mux), Drain: time.Second, Log: log}.Run(ctx, ln)
	_ = client.Stop(context.Background())
	return err
}

func startJobs(ctx context.Context, infra *app.Infra) (*jobs.Client, error) {
	registry := jobs.NewRegistry()
	purge, err := outbox.NewPurgeWorker(infra.Pool, migrations.Modules, infra.Clock, 7*24*time.Hour)
	if err != nil {
		return nil, err
	}
	jobs.Register(registry, purge)
	registry.Daily(3, 0, outbox.PurgeArgs{})
	client, err := jobs.NewClient(infra.Pool, registry, 20, infra.Log)
	if err != nil {
		return nil, err
	}
	return client, client.Start(ctx)
}
