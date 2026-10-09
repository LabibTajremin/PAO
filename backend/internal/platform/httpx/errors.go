// Package httpx is the HTTP edge shared by every module: the error format (PRD §9.6),
// JSON and pagination helpers, spec-driven request validation, middleware and the
// server lifecycle.
package httpx

import (
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"time"
)

// Error is an API error carrying the HTTP status and the stable error code.
type Error struct {
	Status     int
	Code       string
	Message    string
	Details    map[string]any
	RetryAfter time.Duration
	cause      error
}

func (e *Error) Error() string {
	if e.cause != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.cause)
	}
	return e.Code + ": " + e.Message
}

// Unwrap exposes the domain error the API error was mapped from.
func (e *Error) Unwrap() error { return e.cause }

// NewError builds an API error.
func NewError(status int, code, message string) *Error {
	return &Error{Status: status, Code: code, Message: message}
}

// WithDetails returns a copy with details attached.
func (e *Error) WithDetails(details map[string]any) *Error {
	c := *e
	c.Details = details
	return &c
}

// Wrap returns a copy that remembers the underlying error for logs.
func (e *Error) Wrap(cause error) *Error {
	c := *e
	c.cause = cause
	return &c
}

// Common errors.
var (
	ErrUnauthenticated = NewError(http.StatusUnauthorized, "UNAUTHENTICATED", "Sign in again.")
	ErrForbidden       = NewError(http.StatusForbidden, "FORBIDDEN", "You do not have permission for this action.")
	ErrNotFound        = NewError(http.StatusNotFound, "NOT_FOUND", "Not found.")
	ErrValidation      = NewError(http.StatusUnprocessableEntity, "VALIDATION_FAILED", "Invalid request.")
	ErrInternal        = NewError(http.StatusInternalServerError, "INTERNAL", "Something went wrong.")
	ErrNotImplemented  = NewError(http.StatusNotImplemented, "NOT_IMPLEMENTED", "Not available yet.")
)

// ErrorMap maps domain errors to API errors; each module's adapter/http owns one, so
// error codes exist only at the HTTP edge (01-conventions.md §4).
type ErrorMap map[error]*Error

// Map returns the API error for err (matched with errors.Is), or err unchanged.
func (m ErrorMap) Map(err error) error {
	for domainErr, apiErr := range m {
		if errors.Is(err, domainErr) {
			return apiErr.Wrap(err)
		}
	}
	return err
}

// WriteError writes err in the single error format. Errors that are not *Error become
// 500 INTERNAL and are logged; their text never reaches the client.
func WriteError(w http.ResponseWriter, r *http.Request, log *slog.Logger, err error) {
	var apiErr *Error
	if !errors.As(err, &apiErr) {
		log.ErrorContext(r.Context(), "unhandled error", "error", err, "path", r.URL.Path)
		apiErr = ErrInternal
	}
	if apiErr.RetryAfter > 0 {
		w.Header().Set("Retry-After", strconv.Itoa(int(apiErr.RetryAfter.Seconds())))
	}
	body := map[string]any{"code": apiErr.Code, "message": apiErr.Message}
	if len(apiErr.Details) > 0 {
		body["details"] = apiErr.Details
	}
	WriteJSON(w, apiErr.Status, map[string]any{"error": body})
}

// RateLimited builds a 429 with Retry-After.
func RateLimited(code string, retryAfter time.Duration) *Error {
	e := NewError(http.StatusTooManyRequests, code, "Too many requests. Try again later.")
	e.RetryAfter = retryAfter
	return e
}
