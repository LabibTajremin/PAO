// Package metrics exposes Prometheus metrics for requests, errors and latency on the
// internal metrics port (PRD §11).
package metrics

import (
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Metrics owns a registry so nothing is registered globally.
type Metrics struct {
	Registry *prometheus.Registry
	requests *prometheus.CounterVec
	latency  *prometheus.HistogramVec
}

// New registers the HTTP and Go runtime collectors.
func New() *Metrics {
	m := &Metrics{
		Registry: prometheus.NewRegistry(),
		requests: prometheus.NewCounterVec(prometheus.CounterOpts{
			Name: "pao_http_requests_total", Help: "HTTP requests by route, method and status.",
		}, []string{"route", "method", "status"}),
		latency: prometheus.NewHistogramVec(prometheus.HistogramOpts{
			Name: "pao_http_request_duration_seconds", Help: "HTTP request latency by route.",
			Buckets: []float64{.01, .025, .05, .1, .2, .3, .5, 1, 2, 5},
		}, []string{"route", "method"}),
	}
	m.Registry.MustRegister(m.requests, m.latency, collectors.NewGoCollector(), collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}))
	return m
}

// Handler serves the registry in the Prometheus text format.
func (m *Metrics) Handler() http.Handler {
	return promhttp.HandlerFor(m.Registry, promhttp.HandlerOpts{})
}

// Middleware records each request under its chi route pattern, so IDs in paths do not
// explode label cardinality.
func (m *Metrics) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		route := "unmatched"
		if rc := chi.RouteContext(r.Context()); rc != nil && rc.RoutePattern() != "" {
			route = rc.RoutePattern()
		}
		m.requests.WithLabelValues(route, r.Method, strconv.Itoa(rec.status)).Inc()
		m.latency.WithLabelValues(route, r.Method).Observe(time.Since(start).Seconds())
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}
