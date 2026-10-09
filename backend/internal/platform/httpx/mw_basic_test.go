package httpx

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

var ok200 = http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })

func TestRequestID(t *testing.T) {
	var seen string
	h := RequestID(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { seen = logx.RequestID(r.Context()) }))
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("X-Request-ID", "client-req-123")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if seen != "client-req-123" || rec.Header().Get("X-Request-ID") != seen {
		t.Fatalf("propagated id = %q", seen)
	}
	req.Header.Set("X-Request-ID", "bad id with spaces")
	h.ServeHTTP(httptest.NewRecorder(), req)
	if len(seen) != 36 {
		t.Fatalf("generated id = %q", seen)
	}
}

func TestRecover_Returns500(t *testing.T) {
	h := Recover(logx.Discard())(http.HandlerFunc(func(http.ResponseWriter, *http.Request) { panic("boom") }))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	if rec.Code != 500 || strings.Contains(rec.Body.String(), "boom") {
		t.Fatalf("got %d %s", rec.Code, rec.Body.String())
	}
	rec = httptest.NewRecorder()
	Recover(logx.Discard())(ok200).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	if rec.Code != 200 {
		t.Fatal("normal request disturbed")
	}
}

func TestSecurityHeaders(t *testing.T) {
	rec := httptest.NewRecorder()
	SecurityHeaders(ok200).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	for _, h := range []string{"X-Content-Type-Options", "X-Frame-Options", "Content-Security-Policy", "Strict-Transport-Security"} {
		if rec.Header().Get(h) == "" {
			t.Errorf("%s missing", h)
		}
	}
}

func TestCORS(t *testing.T) {
	h := CORS("https://admin.pao.bd")(ok200)
	pre := httptest.NewRequest(http.MethodOptions, "/v1/admin/dashboard", nil)
	pre.Header.Set("Origin", "https://admin.pao.bd")
	pre.Header.Set("Access-Control-Request-Method", "GET")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, pre)
	if rec.Code != 204 || rec.Header().Get("Access-Control-Allow-Origin") != "https://admin.pao.bd" {
		t.Fatalf("preflight: %d %v", rec.Code, rec.Header())
	}
	other := httptest.NewRequest(http.MethodGet, "/", nil)
	other.Header.Set("Origin", "https://evil.example")
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, other)
	if rec.Code != 200 || rec.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Fatalf("foreign origin allowed: %v", rec.Header())
	}
}

func TestBodyLimit(t *testing.T) {
	var readErr error
	h := BodyLimit(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { _, readErr = io.ReadAll(r.Body) }))
	h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/", strings.NewReader(strings.Repeat("a", MaxBodyBytes+1))))
	if readErr == nil {
		t.Fatal("oversized body accepted")
	}
}
