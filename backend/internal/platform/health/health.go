// Package health serves the liveness and readiness endpoints used by Docker and load
// balancers.
package health

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
)

// Checker reports whether one dependency (database, Redis, storage) is reachable.
type Checker interface {
	Check(ctx context.Context) error
}

// CheckerFunc adapts a function to the Checker interface.
type CheckerFunc func(ctx context.Context) error

// Check calls f.
func (f CheckerFunc) Check(ctx context.Context) error { return f(ctx) }

// Liveness answers 200 while the process is able to serve HTTP at all.
func Liveness(w http.ResponseWriter, _ *http.Request) {
	writeStatus(w, http.StatusOK, map[string]string{"status": "ok"})
}

// Readiness returns a handler that answers 200 only when every named checker succeeds,
// so traffic is withheld from an instance whose dependencies are down.
func Readiness(checkers map[string]Checker) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		failed := map[string]string{}
		for name, c := range checkers {
			if err := c.Check(r.Context()); err != nil {
				failed[name] = "unavailable"
			}
		}
		if len(failed) > 0 {
			writeStatus(w, http.StatusServiceUnavailable, map[string]any{"status": "unavailable", "checks": failed})
			return
		}
		writeStatus(w, http.StatusOK, map[string]string{"status": "ok"})
	}
}

func writeStatus(w http.ResponseWriter, code int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(body)
}

// Probe performs the container health check: it exits non-zero unless url answers 200.
// The runtime image is distroless, so the binary probes itself instead of using curl.
func Probe(ctx context.Context, client *http.Client, url string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return fmt.Errorf("build probe request: %w", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("probe %s: %w", url, err)
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("probe %s: status %d", url, resp.StatusCode)
	}
	return nil
}
