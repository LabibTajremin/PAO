package httpx

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"time"
)

// NewServer returns an HTTP server with timeouts suited to slow mobile networks.
func NewServer(addr string, h http.Handler) *http.Server {
	return &http.Server{
		Addr: addr, Handler: h,
		ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 20 * time.Second,
		WriteTimeout: 30 * time.Second, IdleTimeout: 90 * time.Second,
	}
}

// Runner serves until its context ends, then drains in-flight requests.
type Runner struct {
	Server *http.Server
	// Drain bounds graceful shutdown; 10 s in production.
	Drain time.Duration
	Log   *slog.Logger
}

// Run serves on ln until ctx ends.
func (r Runner) Run(ctx context.Context, ln net.Listener) error {
	errc := make(chan error, 1)
	go func() { errc <- r.Server.Serve(ln) }()
	r.Log.InfoContext(ctx, "http server listening", "addr", ln.Addr().String())
	select {
	case err := <-errc:
		return fmt.Errorf("http server: %w", err)
	case <-ctx.Done():
	}
	shutdownCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), r.Drain)
	defer cancel()
	if err := r.Server.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("http shutdown: %w", err)
	}
	<-errc
	return nil
}
