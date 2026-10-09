// Command api is the PAO HTTP API. It is the composition root: configuration,
// infrastructure, modules and the server are wired here and in internal/app.
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
	"github.com/LabibTajremin/PAO/backend/internal/platform/health"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		if err := health.Probe(context.Background(), &http.Client{Timeout: 2 * time.Second}, "http://127.0.0.1:8080/healthz"); err != nil {
			os.Exit(1)
		}
		return
	}
	if err := run(); err != nil {
		logx.New(os.Stderr, 0).Error("api stopped", "error", err)
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
	spec, err := api.GetSpec()
	if err != nil {
		return err
	}
	modules, err := app.BuildModules(infra)
	if err != nil {
		return err
	}
	handler, err := app.APIHandler(infra, spec, modules.Server, modules.Identity.Permissions)
	if err != nil {
		return err
	}
	go serveMetrics(ctx, infra)
	ln, err := net.Listen("tcp", cfg.HTTPAddr)
	if err != nil {
		return err
	}
	log.Info("api starting", "config", cfg)
	return httpx.Runner{Server: httpx.NewServer(cfg.HTTPAddr, handler), Drain: 10 * time.Second, Log: log}.Run(ctx, ln)
}

func serveMetrics(ctx context.Context, infra *app.Infra) {
	ln, err := net.Listen("tcp", infra.Config.MetricsAddr)
	if err != nil {
		infra.Log.Error("metrics listener", "error", err)
		return
	}
	mux := http.NewServeMux()
	mux.Handle("GET /metrics", infra.Metrics.Handler())
	_ = httpx.Runner{Server: httpx.NewServer("", mux), Drain: time.Second, Log: infra.Log}.Run(ctx, ln)
}
