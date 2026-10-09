package httpx

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"log/slog"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Limiter is a rate limiter (redisx.RateLimiter).
type Limiter interface {
	Allow(ctx context.Context, key string, limit int, window time.Duration) (redisx.Decision, error)
}

// RateLimits configures per-subject API limits per operation.
type RateLimits struct {
	PerUser int
	PerIP   int
	Window  time.Duration
}

// RateLimit applies a per-user limit to authenticated calls and a per-IP limit to
// anonymous ones, per operation (02-architecture §4 "rl:api").
func RateLimit(l Limiter, keys redisx.Keys, limits RateLimits, log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			op, _ := OperationFrom(r.Context())
			subject, limit := "ip:"+ClientIP(r), limits.PerIP
			if p, ok := PrincipalFrom(r.Context()); ok {
				subject, limit = "user:"+p.AccountID.String(), limits.PerUser
			}
			d, err := l.Allow(r.Context(), keys.Key("rl", "api", subject, op.ID), limit, limits.Window)
			if err != nil {
				WriteError(w, r, log, err)
				return
			}
			if !d.Allowed {
				WriteError(w, r, log, RateLimited("RATE_LIMITED", d.RetryAfter))
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// ClientIP returns the caller's address without the port. ProxiedClientIP has already
// replaced a load balancer's address with the client's.
func ClientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

// IdempotencyStore remembers responses per key (redisx.IdempotencyStore).
type IdempotencyStore interface {
	Reserve(ctx context.Context, key, requestHash string) (redisx.IdempotencyRecord, bool, error)
	Complete(ctx context.Context, key string, rec redisx.IdempotencyRecord) error
	Release(ctx context.Context, key string) error
}

// Idempotency replays the first response for a repeated Idempotency-Key on operations
// that declare the header (PRD §9.6). A key reused with a different body is rejected.
func Idempotency(store IdempotencyStore, keys redisx.Keys, log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			op, _ := OperationFrom(r.Context())
			p, ok := PrincipalFrom(r.Context())
			if !op.Idempotent || !ok {
				next.ServeHTTP(w, r)
				return
			}
			body, _ := io.ReadAll(r.Body)
			r.Body = io.NopCloser(bytes.NewReader(body))
			sum := sha256.Sum256(append([]byte(r.Method+" "+r.URL.Path+"\n"), body...))
			key := keys.Key("idem", p.AccountID.String(), r.Header.Get("Idempotency-Key"))
			serveIdempotent(w, r, next, idempotentCall{store: store, key: key, hash: hex.EncodeToString(sum[:]), log: log})
		})
	}
}

type idempotentCall struct {
	store IdempotencyStore
	key   string
	hash  string
	log   *slog.Logger
}

func serveIdempotent(w http.ResponseWriter, r *http.Request, next http.Handler, c idempotentCall) {
	rec, reserved, err := c.store.Reserve(r.Context(), c.key, c.hash)
	switch {
	case err != nil:
		WriteError(w, r, c.log, err)
	case !reserved && rec.RequestHash != c.hash:
		WriteError(w, r, c.log, NewError(http.StatusUnprocessableEntity, "IDEMPOTENCY_KEY_REUSED", "This Idempotency-Key was used for a different request."))
	case !reserved && !rec.Done:
		WriteError(w, r, c.log, NewError(http.StatusConflict, "CONFLICT", "The first request with this key is still running."))
	case !reserved:
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Idempotent-Replayed", "true")
		w.WriteHeader(rec.Status)
		_, _ = w.Write(rec.Body)
	default:
		capture := &captureWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(capture, r)
		finishIdempotent(r.Context(), c, capture)
	}
}

// finishIdempotent stores successful and client-error answers; server errors release
// the key so the client can retry.
func finishIdempotent(ctx context.Context, c idempotentCall, capture *captureWriter) {
	var err error
	if capture.status >= http.StatusInternalServerError {
		err = c.store.Release(ctx, c.key)
	} else {
		err = c.store.Complete(ctx, c.key, redisx.IdempotencyRecord{RequestHash: c.hash, Status: capture.status, Body: capture.body.Bytes()})
	}
	if err != nil {
		c.log.ErrorContext(ctx, "idempotency bookkeeping failed", "error", err)
	}
}

type captureWriter struct {
	http.ResponseWriter
	status int
	body   bytes.Buffer
}

func (c *captureWriter) WriteHeader(code int) {
	c.status = code
	c.ResponseWriter.WriteHeader(code)
}

func (c *captureWriter) Write(b []byte) (int, error) {
	c.body.Write(b)
	return c.ResponseWriter.Write(b)
}

var privateNets = func() []*net.IPNet {
	var nets []*net.IPNet
	for _, cidr := range []string{"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8", "::1/128", "fc00::/7"} {
		_, n, _ := net.ParseCIDR(cidr)
		nets = append(nets, n)
	}
	return nets
}()

// ProxiedClientIP trusts X-Forwarded-For only when the connection comes from a private
// address (our load balancer), and then takes the rightmost entry — the one the load
// balancer appended — so clients cannot spoof their address for rate limits.
func ProxiedClientIP(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		peer := net.ParseIP(ClientIP(r))
		forwarded := r.Header.Values("X-Forwarded-For")
		if peer != nil && len(forwarded) > 0 && isPrivate(peer) {
			last := forwarded[len(forwarded)-1]
			parts := strings.Split(last, ",")
			if ip := net.ParseIP(strings.TrimSpace(parts[len(parts)-1])); ip != nil {
				r.RemoteAddr = net.JoinHostPort(ip.String(), "0")
			}
		}
		next.ServeHTTP(w, r)
	})
}

func isPrivate(ip net.IP) bool {
	for _, n := range privateNets {
		if n.Contains(ip) {
			return true
		}
	}
	return false
}
