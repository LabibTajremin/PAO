package httpx

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

type fakeVerifier struct {
	claims auth.Claims
	err    error
}

func (f fakeVerifier) Verify(string) (auth.Claims, error) { return f.claims, f.err }

type fakeDenylist struct {
	denied bool
	err    error
}

func (f fakeDenylist) IsDenied(context.Context, string) (bool, error) { return f.denied, f.err }

type fakeChecker struct {
	allowed bool
	err     error
}

func (f fakeChecker) Has(context.Context, []string, string) (bool, error) { return f.allowed, f.err }

func withOp(perm string) *http.Request {
	r := httptest.NewRequest(http.MethodGet, "/", nil)
	return r.WithContext(WithOperation(r.Context(), Operation{ID: "op", Permission: perm}))
}

func TestAuthenticate(t *testing.T) {
	sub := uuid.New()
	good := fakeVerifier{claims: auth.Claims{Subject: sub, Roles: []string{"customer"}, ID: "j1"}}
	tests := []struct {
		name, perm, header string
		v                  fakeVerifier
		deny               fakeDenylist
		status             int
	}{
		{"public skips", PermissionPublic, "", good, fakeDenylist{}, 200},
		{"valid", "booking:create", "Bearer t", good, fakeDenylist{}, 200},
		{"missing", "booking:create", "", good, fakeDenylist{}, 401},
		{"expired", "booking:create", "Bearer t", fakeVerifier{err: auth.ErrTokenExpired}, fakeDenylist{}, 401},
		{"invalid", "booking:create", "Bearer t", fakeVerifier{err: auth.ErrTokenInvalid}, fakeDenylist{}, 401},
		{"revoked", "booking:create", "Bearer t", good, fakeDenylist{denied: true}, 401},
		{"denylist down", "booking:create", "Bearer t", good, fakeDenylist{err: errors.New("down")}, 500},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			var p Principal
			h := Authenticate(tc.v, tc.deny, logx.Discard())(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				p, _ = PrincipalFrom(r.Context())
			}))
			req := withOp(tc.perm)
			if tc.header != "" {
				req.Header.Set("Authorization", tc.header)
			}
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tc.status {
				t.Fatalf("status = %d %s", rec.Code, rec.Body.String())
			}
			if tc.name == "valid" && (p.AccountID != sub || !p.HasRole("customer") || p.HasRole("provider")) {
				t.Fatalf("principal = %+v", p)
			}
		})
	}
}

func TestAuthorize(t *testing.T) {
	p := Principal{AccountID: uuid.New(), Roles: []string{"customer"}, ExpiresAt: time.Now()}
	tests := []struct {
		name, perm string
		signedIn   bool
		checker    fakeChecker
		status     int
	}{
		{"public", PermissionPublic, false, fakeChecker{}, 200},
		{"no x-permission denies", "", true, fakeChecker{allowed: true}, 403},
		{"authenticated", PermissionAuthenticated, true, fakeChecker{}, 200},
		{"anonymous", "booking:create", false, fakeChecker{allowed: true}, 401},
		{"granted", "booking:create", true, fakeChecker{allowed: true}, 200},
		{"refused", "job:respond", true, fakeChecker{}, 403},
		{"checker down", "job:respond", true, fakeChecker{err: errors.New("down")}, 500},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := withOp(tc.perm)
			if tc.signedIn {
				req = req.WithContext(WithPrincipal(req.Context(), p))
			}
			rec := httptest.NewRecorder()
			Authorize(tc.checker, logx.Discard())(ok200).ServeHTTP(rec, req)
			if rec.Code != tc.status {
				t.Fatalf("status = %d", rec.Code)
			}
		})
	}
}
