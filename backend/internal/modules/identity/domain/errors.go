package domain

import "errors"

// Identity errors. adapter/http maps them to API error codes.
var (
	ErrInvalidPhone       = errors.New("not a Bangladeshi mobile number")
	ErrAccountNotFound    = errors.New("account not found")
	ErrAccountBanned      = errors.New("account banned")
	ErrAccountSuspended   = errors.New("account suspended")
	ErrAccountDeleted     = errors.New("account deleted")
	ErrStatusChange       = errors.New("status change not allowed")
	ErrCodeInvalid        = errors.New("one-time code invalid")
	ErrCodeExpired        = errors.New("one-time code expired or never sent")
	ErrCodeLocked         = errors.New("too many wrong codes")
	ErrRateLimited        = errors.New("too many requests")
	ErrRefreshInvalid     = errors.New("refresh token invalid")
	ErrRefreshReused      = errors.New("refresh token reused")
	ErrInvalidCredentials = errors.New("email or password wrong")
	ErrAdminLocked        = errors.New("admin account locked")
	ErrAdminInactive      = errors.New("admin account deactivated")
	ErrChallengeExpired   = errors.New("login challenge expired")
	ErrTOTPInvalid        = errors.New("authenticator code invalid")
	ErrEmailTaken         = errors.New("email already used")
	ErrRoleInvalid        = errors.New("unknown role, permission or screen")
	ErrPasswordTooWeak    = errors.New("password too weak")
	ErrNotAdmin           = errors.New("account is not an admin")
)
