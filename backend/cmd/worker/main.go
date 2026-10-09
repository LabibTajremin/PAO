// Command worker runs the outbox relay and scheduled background jobs. It ships in the
// same image as the API.
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/platform/health"
)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		if err := health.Probe(context.Background(), &http.Client{Timeout: 2 * time.Second}, "http://127.0.0.1:9090/healthz"); err != nil {
			os.Exit(1)
		}
		return
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", health.Liveness)
	srv := &http.Server{Addr: ":9090", Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() { _ = srv.ListenAndServe() }()
	logger.Info("worker started")
	<-ctx.Done()
	_ = srv.Shutdown(context.Background())
	logger.Info("worker stopped")
}
