package httpx

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

type fakeLimiter struct {
	decision redisx.Decision
	err      error
	keys     []string
	limits   []int
}

func (f *fakeLimiter) Allow(_ context.Context, key string, limit int, _ time.Duration) (redisx.Decision, error) {
	f.keys, f.limits = append(f.keys, key), append(f.limits, limit)
	return f.decision, f.err
}

func TestRateLimit(t *testing.T) {
	limits := RateLimits{PerUser: 60, PerIP: 30, Window: time.Minute}
	keys := redisx.NewKeys("t")
	l := &fakeLimiter{decision: redisx.Decision{Allowed: true}}
	h := RateLimit(l, keys, limits, logx.Discard())(ok200)
	anon := withOp("public")
	anon.RemoteAddr = "10.0.0.1:5555"
	h.ServeHTTP(httptest.NewRecorder(), anon)
	user := withOp("x")
	id := uuid.New()
	h.ServeHTTP(httptest.NewRecorder(), user.WithContext(WithPrincipal(user.Context(), Principal{AccountID: id})))
	if l.keys[0] != "pao:t:rl:api:ip:10.0.0.1:op" || l.limits[0] != 30 || l.keys[1] != "pao:t:rl:api:user:"+id.String()+":op" || l.limits[1] != 60 {
		t.Fatalf("keys %v limits %v", l.keys, l.limits)
	}
	for name, f := range map[string]*fakeLimiter{
		"blocked": {decision: redisx.Decision{RetryAfter: 5 * time.Second}},
		"down":    {err: errors.New("down")},
	} {
		rec := httptest.NewRecorder()
		RateLimit(f, keys, limits, logx.Discard())(ok200).ServeHTTP(rec, withOp("x"))
		if (name == "blocked" && (rec.Code != 429 || rec.Header().Get("Retry-After") != "5")) || (name == "down" && rec.Code != 500) {
			t.Errorf("%s: %d", name, rec.Code)
		}
	}
	if ClientIP(&http.Request{RemoteAddr: "no-port"}) != "no-port" {
		t.Fatal("address without port mangled")
	}
}

type memStore struct {
	recs                  map[string]redisx.IdempotencyRecord
	reserveErr, finishErr error
	completed, released   int
}

func (m *memStore) Reserve(_ context.Context, key, hash string) (redisx.IdempotencyRecord, bool, error) {
	if m.reserveErr != nil {
		return redisx.IdempotencyRecord{}, false, m.reserveErr
	}
	if rec, ok := m.recs[key]; ok {
		return rec, false, nil
	}
	m.recs[key] = redisx.IdempotencyRecord{RequestHash: hash}
	return m.recs[key], true, nil
}

func (m *memStore) Complete(_ context.Context, key string, rec redisx.IdempotencyRecord) error {
	m.completed++
	rec.Done = true
	m.recs[key] = rec
	return m.finishErr
}

func (m *memStore) Release(_ context.Context, key string) error {
	m.released++
	delete(m.recs, key)
	return m.finishErr
}

func idemRequest(body string) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/v1/customer/bookings", strings.NewReader(body))
	r.Header.Set("Idempotency-Key", "key-12345")
	ctx := WithOperation(r.Context(), Operation{ID: "createBooking", Idempotent: true})
	return r.WithContext(WithPrincipal(ctx, Principal{AccountID: uuid.MustParse("00000000-0000-7000-8000-000000000001")}))
}

func TestIdempotency(t *testing.T) {
	store := &memStore{recs: map[string]redisx.IdempotencyRecord{}}
	calls := 0
	h := Idempotency(store, redisx.NewKeys("t"), logx.Discard())(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		WriteJSON(w, http.StatusCreated, map[string]int{"n": calls})
	}))
	first := httptest.NewRecorder()
	h.ServeHTTP(first, idemRequest(`{"a":1}`))
	replay := httptest.NewRecorder()
	h.ServeHTTP(replay, idemRequest(`{"a":1}`))
	if calls != 1 || replay.Code != 201 || replay.Body.String() != first.Body.String() || replay.Header().Get("Idempotent-Replayed") != "true" {
		t.Fatalf("replay: calls=%d %d %s", calls, replay.Code, replay.Body.String())
	}
	reused := httptest.NewRecorder()
	h.ServeHTTP(reused, idemRequest(`{"a":2}`))
	if reused.Code != 422 {
		t.Fatalf("reused key: %d", reused.Code)
	}
	key := "pao:t:idem:00000000-0000-7000-8000-000000000001:key-12345"
	store.recs[key] = redisx.IdempotencyRecord{RequestHash: store.recs[key].RequestHash}
	inflight := httptest.NewRecorder()
	h.ServeHTTP(inflight, idemRequest(`{"a":1}`))
	if inflight.Code != 409 {
		t.Fatalf("in flight: %d", inflight.Code)
	}
}

func TestIdempotency_EdgeCases(t *testing.T) {
	keys := redisx.NewKeys("t")
	failing := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(500) })
	store := &memStore{recs: map[string]redisx.IdempotencyRecord{}, finishErr: errors.New("down")}
	Idempotency(store, keys, logx.Discard())(failing).ServeHTTP(httptest.NewRecorder(), idemRequest(`{}`))
	if store.released != 1 || store.completed != 0 {
		t.Fatalf("server error not released: %+v", store)
	}
	down := &memStore{recs: map[string]redisx.IdempotencyRecord{}, reserveErr: errors.New("down")}
	rec := httptest.NewRecorder()
	Idempotency(down, keys, logx.Discard())(ok200).ServeHTTP(rec, idemRequest(`{}`))
	if rec.Code != 500 {
		t.Fatalf("store down: %d", rec.Code)
	}
	rec = httptest.NewRecorder()
	Idempotency(down, keys, logx.Discard())(ok200).ServeHTTP(rec, withOp("x"))
	if rec.Code != 200 {
		t.Fatal("non-idempotent operation intercepted")
	}
}

func TestProxiedClientIP(t *testing.T) {
	var seen string
	h := ProxiedClientIP(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { seen = ClientIP(r) }))
	tests := []struct{ remote, xff, want string }{
		{"10.0.0.5:443", "1.2.3.4, 203.0.113.9", "203.0.113.9"},
		{"203.0.113.50:443", "1.2.3.4", "203.0.113.50"},
		{"10.0.0.5:443", "", "10.0.0.5"},
		{"10.0.0.5:443", "garbage", "10.0.0.5"},
	}
	for _, tc := range tests {
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		r.RemoteAddr = tc.remote
		if tc.xff != "" {
			r.Header.Set("X-Forwarded-For", tc.xff)
		}
		h.ServeHTTP(httptest.NewRecorder(), r)
		if seen != tc.want {
			t.Errorf("remote %s xff %q: got %s, want %s", tc.remote, tc.xff, seen, tc.want)
		}
	}
}
