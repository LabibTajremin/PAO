package httpx

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

type stubAPI struct{ api.StrictUnimplemented }

func (stubAPI) GetMe(context.Context, api.GetMeRequestObject) (api.GetMeResponseObject, error) {
	return api.GetMe200JSONResponse{Id: uuid.Nil, Roles: []api.Role{api.RoleCustomer}, Status: api.AccountStatusActive}, nil
}

func newAPIRouter(t *testing.T) http.Handler {
	t.Helper()
	spec, err := api.GetSpec()
	if err != nil {
		t.Fatal(err)
	}
	sr, err := NewSpecRouter(spec, logx.Discard())
	if err != nil {
		t.Fatal(err)
	}
	return NewRouter(RouterDeps{
		Log: logx.Discard(), Spec: sr, Metrics: func(h http.Handler) http.Handler { return h },
		Verifier:    fakeVerifier{claims: auth.Claims{Subject: uuid.New(), Roles: []string{"customer"}, ID: "j"}},
		Revoked:     fakeDenylist{},
		Permissions: fakeChecker{allowed: true},
		Limiter:     &fakeLimiter{decision: redisx.Decision{Allowed: true}},
		Keys:        redisx.NewKeys("t"), Limits: RateLimits{PerUser: 10, PerIP: 10, Window: time.Minute},
		Idempotency: &memStore{recs: map[string]redisx.IdempotencyRecord{}},
		AdminOrigin: "http://admin", API: stubAPI{},
		Mount: func(r chi.Router) {
			r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(200) })
		},
	})
}

func TestNewRouter_ServesThroughTheChain(t *testing.T) {
	h := newAPIRouter(t)
	tests := []struct {
		name, method, path, body string
		token                    bool
		status                   int
		contains                 string
	}{
		{"mounted route", "GET", "/healthz", "", false, 200, ""},
		{"implemented", "GET", "/v1/me", "", true, 200, `"status":"active"`},
		{"needs token", "GET", "/v1/me", "", false, 401, "UNAUTHENTICATED"},
		{"not built yet", "GET", "/v1/customer/catalog", "", true, 501, "NOT_IMPLEMENTED"},
		{"schema violation", "POST", "/v1/auth/otp/request", `{"phone":"123"}`, false, 422, "VALIDATION_FAILED"},
		{"unknown route", "GET", "/v1/nope", "", true, 404, "NOT_FOUND"},
		{"wrong method", "DELETE", "/healthz", "", false, 405, "NOT_FOUND"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, strings.NewReader(tc.body))
			req.Header.Set("Content-Type", "application/json")
			if tc.token {
				req.Header.Set("Authorization", "Bearer t")
			}
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tc.status || !strings.Contains(rec.Body.String(), tc.contains) {
				t.Fatalf("got %d %s", rec.Code, rec.Body.String())
			}
		})
	}
}

func TestErrorHandlers(t *testing.T) {
	rec := httptest.NewRecorder()
	validationError(logx.Discard())(rec, httptest.NewRequest("GET", "/", nil), context.Canceled)
	if rec.Code != 422 {
		t.Fatalf("validation: %d", rec.Code)
	}
	rec = httptest.NewRecorder()
	responseError(logx.Discard())(rec, httptest.NewRequest("GET", "/", nil), ErrForbidden)
	if rec.Code != 403 {
		t.Fatalf("response: %d", rec.Code)
	}
}
