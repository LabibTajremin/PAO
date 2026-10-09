package health

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestLiveness_ReturnsOK(t *testing.T) {
	rec := httptest.NewRecorder()
	Liveness(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusOK || rec.Body.String() != "{\"status\":\"ok\"}\n" {
		t.Fatalf("got %d %q", rec.Code, rec.Body.String())
	}
}

func TestReadiness_OKWhenAllCheckersPass(t *testing.T) {
	h := Readiness(map[string]Checker{"db": CheckerFunc(func(context.Context) error { return nil })})
	rec := httptest.NewRecorder()
	h(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("got %d", rec.Code)
	}
}

func TestReadiness_UnavailableWhenACheckerFails(t *testing.T) {
	h := Readiness(map[string]Checker{
		"db":    CheckerFunc(func(context.Context) error { return nil }),
		"redis": CheckerFunc(func(context.Context) error { return errors.New("down") }),
	})
	rec := httptest.NewRecorder()
	h(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	want := "{\"checks\":{\"redis\":\"unavailable\"},\"status\":\"unavailable\"}\n"
	if rec.Code != http.StatusServiceUnavailable || rec.Body.String() != want {
		t.Fatalf("got %d %q", rec.Code, rec.Body.String())
	}
}

func TestProbe(t *testing.T) {
	ok := httptest.NewServer(http.HandlerFunc(Liveness))
	defer ok.Close()
	down := httptest.NewServer(Readiness(map[string]Checker{"db": CheckerFunc(func(context.Context) error { return errors.New("x") })}))
	defer down.Close()

	tests := []struct {
		name    string
		url     string
		wantErr bool
	}{
		{"healthy", ok.URL, false},
		{"unhealthy status", down.URL, true},
		{"unreachable", "http://127.0.0.1:1", true},
		{"invalid url", "://bad", true},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			err := Probe(context.Background(), http.DefaultClient, tc.url)
			if (err != nil) != tc.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tc.wantErr)
			}
		})
	}
}
