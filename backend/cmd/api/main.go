// Command api is the PAO HTTP API. It is the composition root: configuration,
// infrastructure, modules and the server are wired here and nowhere else.
package main

import (
	"context"
	"errors"
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
		if err := health.Probe(context.Background(), &http.Client{Timeout: 2 * time.Second}, "http://127.0.0.1:8080/healthz"); err != nil {
			os.Exit(1)
		}
		return
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", health.Liveness)
	srv := &http.Server{Addr: ":8080", Handler: mux, ReadHeaderTimeout: 5 * time.Second}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("api server stopped", "error", err)
			os.Exit(1)
		}
	}()
	logger.Info("api listening", "addr", srv.Addr)
	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("api shutdown", "error", err)
	}
}
