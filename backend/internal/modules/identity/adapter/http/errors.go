package http

import (
	"errors"
	"net/http"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
)

var errorMap = httpx.ErrorMap{
	domain.ErrInvalidPhone:       httpx.ErrValidation.WithDetails(map[string]any{"field": "phone"}),
	domain.ErrAccountNotFound:    httpx.ErrNotFound,
	domain.ErrAccountBanned:      httpx.NewError(http.StatusForbidden, "ACCOUNT_BANNED", "This account is banned."),
	domain.ErrAccountSuspended:   httpx.NewError(http.StatusForbidden, "ACCOUNT_SUSPENDED", "This account is suspended."),
	domain.ErrAccountDeleted:     httpx.ErrUnauthenticated,
	domain.ErrStatusChange:       httpx.NewError(http.StatusConflict, "CONFLICT", "The account is already in that state."),
	domain.ErrCodeInvalid:        httpx.NewError(http.StatusUnauthorized, "OTP_INVALID", "The code is wrong."),
	domain.ErrCodeExpired:        httpx.NewError(http.StatusUnauthorized, "OTP_EXPIRED", "The code expired. Ask for a new one."),
	domain.ErrCodeLocked:         httpx.RateLimited("OTP_LOCKED", domain.CodeTTL),
	domain.ErrRefreshInvalid:     httpx.NewError(http.StatusUnauthorized, "REFRESH_TOKEN_INVALID", "Sign in again."),
	domain.ErrRefreshReused:      httpx.NewError(http.StatusUnauthorized, "REFRESH_TOKEN_INVALID", "Sign in again."),
	domain.ErrInvalidCredentials: httpx.NewError(http.StatusUnauthorized, "INVALID_CREDENTIALS", "Email or password is wrong."),
	domain.ErrAdminLocked:        httpx.RateLimited("ACCOUNT_LOCKED", domain.AdminLockout),
	domain.ErrAdminInactive:      httpx.ErrForbidden,
	domain.ErrChallengeExpired:   httpx.NewError(http.StatusUnauthorized, "MFA_CHALLENGE_EXPIRED", "Sign in again."),
	domain.ErrTOTPInvalid:        httpx.NewError(http.StatusUnauthorized, "TOTP_INVALID", "The authenticator code is wrong."),
	domain.ErrEmailTaken:         httpx.NewError(http.StatusConflict, "CONFLICT", "That email is already used."),
	domain.ErrRoleInvalid:        httpx.NewError(http.StatusUnprocessableEntity, "ROLE_INVALID", "Unknown role, permission or screen."),
	domain.ErrPasswordTooWeak:    httpx.ErrValidation.WithDetails(map[string]any{"field": "newPassword"}),
}

// mapError turns identity errors into API errors; a rate limit keeps its wait time.
func mapError(err error) error {
	var rl *app.RateLimitError
	if errors.As(err, &rl) {
		return httpx.RateLimited("RATE_LIMITED", rl.RetryAfter)
	}
	return errorMap.Map(err)
}
