package httpx

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

var errDomain = errors.New("booking already accepted")

func TestErrorMap_MapsWrappedDomainErrors(t *testing.T) {
	m := ErrorMap{errDomain: NewError(http.StatusConflict, "BOOKING_ALREADY_RESPONDED", "Already answered.")}
	var apiErr *Error
	if !errors.As(m.Map(errors.Join(errors.New("ctx"), errDomain)), &apiErr) || apiErr.Code != "BOOKING_ALREADY_RESPONDED" {
		t.Fatalf("not mapped: %v", apiErr)
	}
	if !errors.Is(apiErr, errDomain) || !strings.Contains(apiErr.Error(), "Already answered") {
		t.Fatalf("cause lost: %v", apiErr)
	}
	other := errors.New("other")
	if m.Map(other) != other {
		t.Fatal("unmapped error changed")
	}
	if ErrForbidden.Error() != "FORBIDDEN: You do not have permission for this action." {
		t.Fatalf("Error() = %q", ErrForbidden.Error())
	}
}

func TestWriteError(t *testing.T) {
	tests := []struct {
		name, want string
		err        error
		status     int
	}{
		{"api error with details", `{"error":{"code":"VALIDATION_FAILED","details":{"field":"phone"},"message":"Invalid request."}}`,
			ErrValidation.WithDetails(map[string]any{"field": "phone"}), 422},
		{"unknown error hidden", `{"error":{"code":"INTERNAL","message":"Something went wrong."}}`, errors.New("db down"), 500},
		{"rate limited", `{"error":{"code":"RATE_LIMITED","message":"Too many requests. Try again later."}}`, RateLimited("RATE_LIMITED", 30*time.Second), 429},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			WriteError(rec, httptest.NewRequest(http.MethodGet, "/", nil), logx.Discard(), tc.err)
			if rec.Code != tc.status || strings.TrimSpace(rec.Body.String()) != tc.want {
				t.Fatalf("got %d %s", rec.Code, rec.Body.String())
			}
		})
	}
	rec := httptest.NewRecorder()
	WriteError(rec, httptest.NewRequest(http.MethodGet, "/", nil), logx.Discard(), RateLimited("RATE_LIMITED", 30*time.Second))
	if rec.Header().Get("Retry-After") != "30" {
		t.Fatalf("Retry-After = %q", rec.Header().Get("Retry-After"))
	}
}

func TestCursor_RoundTripAndValidation(t *testing.T) {
	c := Cursor{CreatedAt: time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC), ID: uuid.New()}
	s := EncodeCursor(c)
	got, err := DecodeCursor(&s)
	if err != nil || !got.CreatedAt.Equal(c.CreatedAt) || got.ID != c.ID {
		t.Fatalf("round trip: %+v %v", got, err)
	}
	empty := ""
	if got, err := DecodeCursor(&empty); got != nil || err != nil {
		t.Fatal("empty cursor is not the first page")
	}
	if got, err := DecodeCursor(nil); got != nil || err != nil {
		t.Fatal("nil cursor is not the first page")
	}
	for _, bad := range []string{"%%%", "bm90LWpzb24", "e30"} {
		if _, err := DecodeCursor(&bad); err == nil {
			t.Errorf("cursor %q accepted", bad)
		}
	}
}

func TestPageSize(t *testing.T) {
	zero, big, ok := 0, 500, 30
	for _, tc := range []struct {
		in   *int
		want int
	}{{nil, 20}, {&zero, 20}, {&big, 100}, {&ok, 30}} {
		if got := PageSize(tc.in); got != tc.want {
			t.Errorf("PageSize(%v) = %d", tc.in, got)
		}
	}
}
