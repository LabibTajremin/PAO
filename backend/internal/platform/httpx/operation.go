package httpx

import (
	"context"
	"errors"
	"log/slog"
	"net/http"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/getkin/kin-openapi/openapi3filter"
	"github.com/getkin/kin-openapi/routers"
	"github.com/getkin/kin-openapi/routers/legacy"
)

// Permissions with special meaning in x-permission.
const (
	PermissionPublic        = "public"
	PermissionAuthenticated = "authenticated"
)

// Operation describes the OpenAPI operation matched for a request.
type Operation struct {
	ID string
	// Permission is the operation's x-permission; empty means the spec forgot it and
	// the request is denied (deny by default, 02-architecture.md §7).
	Permission string
	// Idempotent is true when the operation takes an Idempotency-Key header.
	Idempotent bool
}

type operationKey struct{}

// OperationFrom returns the operation matched by SpecRouter.
func OperationFrom(ctx context.Context) (Operation, bool) {
	op, ok := ctx.Value(operationKey{}).(Operation)
	return op, ok
}

// WithOperation stores op in ctx; used by SpecRouter and tests.
func WithOperation(ctx context.Context, op Operation) context.Context {
	return context.WithValue(ctx, operationKey{}, op)
}

// SpecRouter matches requests to api/openapi.yaml operations and validates them, so
// handlers only see requests the contract allows.
type SpecRouter struct {
	router routers.Router
	log    *slog.Logger
}

// NewSpecRouter builds the matcher. Servers are cleared so paths match on any host.
func NewSpecRouter(spec *openapi3.T, log *slog.Logger) (*SpecRouter, error) {
	spec.Servers = nil
	router, err := legacy.NewRouter(spec)
	if err != nil {
		return nil, err
	}
	return &SpecRouter{router: router, log: log}, nil
}

// Middleware rejects unknown routes (404/405) and invalid requests (422), then stores
// the matched Operation in the context.
func (s *SpecRouter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		route, params, err := s.router.FindRoute(r)
		if err != nil {
			WriteError(w, r, s.log, routeError(err))
			return
		}
		input := &openapi3filter.RequestValidationInput{
			Request: r, PathParams: params, Route: route,
			Options: &openapi3filter.Options{AuthenticationFunc: openapi3filter.NoopAuthenticationFunc},
		}
		if err := openapi3filter.ValidateRequest(r.Context(), input); err != nil {
			WriteError(w, r, s.log, ErrValidation.WithDetails(map[string]any{"reason": err.Error()}))
			return
		}
		next.ServeHTTP(w, r.WithContext(WithOperation(r.Context(), describe(route.Operation))))
	})
}

// routeError compares by reason because the router returns fresh RouteError values.
func routeError(err error) *Error {
	var re *routers.RouteError
	if errors.As(err, &re) && re.Reason == routers.ErrMethodNotAllowed.Error() {
		return NewError(http.StatusMethodNotAllowed, "NOT_FOUND", "Method not allowed.")
	}
	return ErrNotFound
}

func describe(op *openapi3.Operation) Operation {
	perm, _ := op.Extensions["x-permission"].(string)
	d := Operation{ID: op.OperationID, Permission: perm}
	for _, p := range op.Parameters {
		if p.Value != nil && p.Value.In == openapi3.ParameterInHeader && p.Value.Name == "Idempotency-Key" {
			d.Idempotent = true
		}
	}
	return d
}
