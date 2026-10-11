package api

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"
)

// session is a caller; without a token it is anonymous. IP is the address the caller
// appears to connect from: the API trusts X-Forwarded-For from the private network the
// test runner reaches it through, and every actor gets its own address so the per-IP
// limits treat them as the separate devices they stand for.
type session struct {
	ID    string
	Token string
	IP    string
}

// response is a decoded API reply.
type response struct {
	Status int
	Body   []byte
}

// JSON decodes the body as an object.
func (r response) JSON(t *testing.T) map[string]any {
	t.Helper()
	var m map[string]any
	if err := json.Unmarshal(r.Body, &m); err != nil {
		t.Fatalf("decode %s: %v", r.Body, err)
	}
	return m
}

// Code is the error code of a failed call.
func (r response) Code(t *testing.T) string {
	t.Helper()
	e, _ := r.JSON(t)["error"].(map[string]any)
	code, _ := e["code"].(string)
	return code
}

var httpClient = &http.Client{Timeout: 30 * time.Second}

// call sends a JSON request to base+path as s; headers are extra name, value pairs.
func call(t *testing.T, base, method, path string, body any, s session, headers ...string) response {
	t.Helper()
	var rd io.Reader
	if body != nil {
		raw, _ := json.Marshal(body)
		rd = bytes.NewReader(raw)
	}
	// Not t.Context(): it is cancelled before cleanups run, and cleanups call the API
	// too (restoring settings, going offline). httpClient's timeout bounds the call.
	req, err := http.NewRequestWithContext(context.WithoutCancel(t.Context()), method, base+path, rd)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	if s.Token != "" {
		req.Header.Set("Authorization", "Bearer "+s.Token)
	}
	if s.IP != "" {
		req.Header.Set("X-Forwarded-For", s.IP)
	}
	for i := 0; i+1 < len(headers); i += 2 {
		req.Header.Set(headers[i], headers[i+1])
	}
	res, err := httpClient.Do(req)
	if err != nil {
		t.Fatalf("%s %s: %v", method, path, err)
	}
	defer func() { _ = res.Body.Close() }()
	raw, _ := io.ReadAll(res.Body)
	return response{Status: res.StatusCode, Body: raw}
}

// do calls the API.
func do(t *testing.T, method, path string, body any, s session, headers ...string) response {
	t.Helper()
	return call(t, stack.api, method, path, body, s, headers...)
}

// must calls the API and fails unless the status is want.
func must(t *testing.T, want int, method, path string, body any, s session, headers ...string) map[string]any {
	t.Helper()
	r := do(t, method, path, body, s, headers...)
	if r.Status != want {
		t.Fatalf("%s %s: want %d, got %d %s", method, path, want, r.Status, r.Body)
	}
	if len(r.Body) == 0 {
		return nil
	}
	return r.JSON(t)
}

// eventually retries check until it passes or the deadline expires; the worker
// relays events asynchronously, so effects of an action land shortly after it.
func eventually(t *testing.T, within time.Duration, what string, check func() bool) {
	t.Helper()
	deadline := time.Now().Add(within)
	for !check() {
		if time.Now().After(deadline) {
			t.Fatalf("timed out waiting for %s", what)
		}
		time.Sleep(200 * time.Millisecond)
	}
}
