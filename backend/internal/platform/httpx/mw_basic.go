package httpx

import (
	"log/slog"
	"net/http"
	"regexp"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

// MaxBodyBytes caps request bodies; files go straight to storage (02-architecture §7).
const MaxBodyBytes = 1 << 20

var requestIDPattern = regexp.MustCompile(`^[A-Za-z0-9._-]{8,64}$`)

// RequestID propagates a well-formed X-Request-ID or issues one, and logs with it.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-ID")
		if !requestIDPattern.MatchString(id) {
			id = uuid.NewString()
		}
		w.Header().Set("X-Request-ID", id)
		next.ServeHTTP(w, r.WithContext(logx.WithRequestID(r.Context(), id)))
	})
}

// Recover turns a panic into a logged 500 without leaking the stack to the client.
func Recover(log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if p := recover(); p != nil {
					log.ErrorContext(r.Context(), "panic serving request", "panic", p, "path", r.URL.Path)
					WriteError(w, r, log, ErrInternal)
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}

// SecurityHeaders sets the headers from 02-architecture.md §7 on every response.
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		h.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		next.ServeHTTP(w, r)
	})
}

// CORS allows only the admin web origin, with credentials for the refresh cookie.
func CORS(origin string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Header.Get("Origin") == origin {
				h := w.Header()
				h.Set("Access-Control-Allow-Origin", origin)
				h.Set("Access-Control-Allow-Credentials", "true")
				h.Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
				h.Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key, X-Request-ID")
				h.Set("Access-Control-Max-Age", "600")
				h.Add("Vary", "Origin")
			}
			if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
				w.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// BodyLimit rejects bodies over MaxBodyBytes when they are read.
func BodyLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		r.Body = http.MaxBytesReader(w, r.Body, MaxBodyBytes)
		next.ServeHTTP(w, r)
	})
}
