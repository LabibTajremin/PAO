package domain

import (
	"time"
	"unicode"

	"github.com/google/uuid"
)

// Admin login rules (A-01).
const (
	AdminMaxFailures  = 5
	AdminLockout      = 15 * time.Minute
	ChallengeTTL      = 5 * time.Minute
	ChallengeAttempts = 5
	MinPasswordLength = 12
)

// Admin is an operations staff member's account plus credentials.
type Admin struct {
	Account
	PasswordHash       string
	MustChangePassword bool
	TOTPSecretEnc      []byte
	TOTPEnrolled       bool
	FailedAttempts     int
	LockedUntil        *time.Time
	Active             bool
	LastLoginAt        *time.Time
}

// CheckCanLogin reports a deactivated or locked admin.
func (a Admin) CheckCanLogin(now time.Time) error {
	if !a.Active || a.DeletedAt != nil {
		return ErrAdminInactive
	}
	if a.LockedUntil != nil && now.Before(*a.LockedUntil) {
		return ErrAdminLocked
	}
	return nil
}

// RecordFailure counts a wrong password and locks the account after the limit.
func (a *Admin) RecordFailure(now time.Time) {
	a.FailedAttempts++
	if a.FailedAttempts >= AdminMaxFailures {
		until := now.Add(AdminLockout)
		a.LockedUntil = &until
		a.FailedAttempts = 0
	}
}

// RecordSuccess clears failures after a correct password.
func (a *Admin) RecordSuccess() {
	a.FailedAttempts = 0
	a.LockedUntil = nil
}

// Challenge is the pending second login step (mfa:{id} in Redis).
type Challenge struct {
	ID       string
	AdminID  uuid.UUID
	Attempts int
	// EnrolSecret is set on first login: the code must match this new secret, which is
	// then saved.
	EnrolSecret string
}

// ValidatePassword requires a passphrase-length password with letters and another
// character class.
func ValidatePassword(pw string) error {
	if len([]rune(pw)) < MinPasswordLength {
		return ErrPasswordTooWeak
	}
	var letter, other bool
	for _, r := range pw {
		if unicode.IsLetter(r) {
			letter = true
		} else {
			other = true
		}
	}
	if !letter || !other {
		return ErrPasswordTooWeak
	}
	return nil
}
