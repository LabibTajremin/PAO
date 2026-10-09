package metrics

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
)

func TestMiddleware_RecordsRoutePattern(t *testing.T) {
	m := New()
	r := chi.NewRouter()
	r.Use(m.Middleware)
	r.Get("/v1/bookings/{id}", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusTeapot) })
	r.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/v1/bookings/123", nil))
	m.Middleware(http.NotFoundHandler()).ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/x", nil))

	rec := httptest.NewRecorder()
	m.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	body := rec.Body.String()
	for _, want := range []string{
		`pao_http_requests_total{method="GET",route="/v1/bookings/{id}",status="418"} 1`,
		`route="unmatched",status="404"`,
		`pao_http_request_duration_seconds_count{method="GET",route="/v1/bookings/{id}"} 1`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("metrics missing %s", want)
		}
	}
}
