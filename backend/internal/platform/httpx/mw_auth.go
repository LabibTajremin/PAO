package httpx

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

// Principal is the authenticated caller.
type Principal struct {
	AccountID uuid.UUID
	Roles     []string
	TokenID   string
	ExpiresAt time.Time
}

// HasRole reports whether the principal holds role.
func (p Principal) HasRole(role string) bool {
	for _, r := range p.Roles {
		if r == role {
			return true
		}
	}
	return false
}

type principalKey struct{}

// PrincipalFrom returns the authenticated caller, if any.
func PrincipalFrom(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey{}).(Principal)
	return p, ok
}

// WithPrincipal stores p in ctx; used by Authenticate and tests.
func WithPrincipal(ctx context.Context, p Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, p)
}

// TokenVerifier validates access tokens.
type TokenVerifier interface {
	Verify(token string) (auth.Claims, error)
}

// RevocationChecker reports revoked token IDs.
type RevocationChecker interface {
	IsDenied(ctx context.Context, jti string) (bool, error)
}

// PermissionChecker answers whether roles grant a permission.
type PermissionChecker interface {
	Has(ctx context.Context, roles []string, permission string) (bool, error)
}

// Authenticate requires a valid, unrevoked bearer token on every non-public operation.
func Authenticate(v TokenVerifier, revoked RevocationChecker, log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if op, _ := OperationFrom(r.Context()); op.Permission == PermissionPublic {
				next.ServeHTTP(w, r)
				return
			}
			p, err := principal(r, v, revoked)
			if err != nil {
				WriteError(w, r, log, err)
				return
			}
			ctx := logx.WithUserID(WithPrincipal(r.Context(), p), p.AccountID.String())
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func principal(r *http.Request, v TokenVerifier, revoked RevocationChecker) (Principal, error) {
	token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	if !ok || token == "" {
		return Principal{}, ErrUnauthenticated
	}
	claims, err := v.Verify(token)
	if errors.Is(err, auth.ErrTokenExpired) {
		return Principal{}, NewError(http.StatusUnauthorized, "TOKEN_EXPIRED", "Session expired.")
	}
	if err != nil {
		return Principal{}, ErrUnauthenticated
	}
	denied, err := revoked.IsDenied(r.Context(), claims.ID)
	if err != nil {
		return Principal{}, err
	}
	if denied {
		return Principal{}, ErrUnauthenticated
	}
	return Principal{AccountID: claims.Subject, Roles: claims.Roles, TokenID: claims.ID, ExpiresAt: claims.ExpiresAt}, nil
}

// Authorize enforces the operation's x-permission. A missing x-permission denies the
// request (deny by default).
func Authorize(checker PermissionChecker, log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if err := authorize(r, checker); err != nil {
				WriteError(w, r, log, err)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func authorize(r *http.Request, checker PermissionChecker) error {
	op, _ := OperationFrom(r.Context())
	switch op.Permission {
	case PermissionPublic:
		return nil
	case "":
		return ErrForbidden
	}
	p, ok := PrincipalFrom(r.Context())
	if !ok {
		return ErrUnauthenticated
	}
	if op.Permission == PermissionAuthenticated {
		return nil
	}
	allowed, err := checker.Has(r.Context(), p.Roles, op.Permission)
	if err != nil {
		return err
	}
	if !allowed {
		return ErrForbidden.WithDetails(map[string]any{"permission": op.Permission})
	}
	return nil
}
