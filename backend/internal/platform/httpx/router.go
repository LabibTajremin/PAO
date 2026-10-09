package httpx

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// RouterDeps are the collaborators of the API router.
type RouterDeps struct {
	Log         *slog.Logger
	Spec        *SpecRouter
	Metrics     func(http.Handler) http.Handler
	Verifier    TokenVerifier
	Revoked     RevocationChecker
	Permissions PermissionChecker
	Limiter     Limiter
	Keys        redisx.Keys
	Limits      RateLimits
	Idempotency IdempotencyStore
	AdminOrigin string
	// API serves every operation in the spec; modules implement it together.
	API api.StrictServerInterface
	// Mount adds routes outside the spec (health checks, test helpers).
	Mount func(chi.Router)
}

// NewRouter assembles the middleware chain in front of the generated handlers:
// transport concerns first, then contract validation, authentication, authorisation,
// rate limits and idempotency.
func NewRouter(d RouterDeps) http.Handler {
	r := chi.NewRouter()
	r.Use(ProxiedClientIP, RequestID, Recover(d.Log), SecurityHeaders, CORS(d.AdminOrigin), BodyLimit, d.Metrics)
	r.NotFound(func(w http.ResponseWriter, req *http.Request) { WriteError(w, req, d.Log, ErrNotFound) })
	r.MethodNotAllowed(func(w http.ResponseWriter, req *http.Request) {
		WriteError(w, req, d.Log, NewError(http.StatusMethodNotAllowed, "NOT_FOUND", "Method not allowed."))
	})
	if d.Mount != nil {
		d.Mount(r)
	}
	r.Group(func(g chi.Router) {
		g.Use(d.Spec.Middleware, Authenticate(d.Verifier, d.Revoked, d.Log), Authorize(d.Permissions, d.Log),
			RateLimit(d.Limiter, d.Keys, d.Limits, d.Log), Idempotency(d.Idempotency, d.Keys, d.Log))
		strict := api.NewStrictHandlerWithOptions(d.API, nil, api.StrictHTTPServerOptions{
			RequestErrorHandlerFunc:  validationError(d.Log),
			ResponseErrorHandlerFunc: responseError(d.Log),
		})
		api.HandlerWithOptions(strict, api.ChiServerOptions{BaseRouter: g, ErrorHandlerFunc: validationError(d.Log)})
	})
	return r
}

func validationError(log *slog.Logger) func(http.ResponseWriter, *http.Request, error) {
	return func(w http.ResponseWriter, r *http.Request, err error) {
		WriteError(w, r, log, ErrValidation.WithDetails(map[string]any{"reason": err.Error()}))
	}
}

func responseError(log *slog.Logger) func(http.ResponseWriter, *http.Request, error) {
	return func(w http.ResponseWriter, r *http.Request, err error) {
		if errors.Is(err, api.ErrNotImplemented) {
			err = ErrNotImplemented
		}
		WriteError(w, r, log, err)
	}
}
