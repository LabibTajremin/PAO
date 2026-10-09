package auth

import (
	"fmt"
	"time"

	"github.com/pquerna/otp"
	"github.com/pquerna/otp/totp"
)

// NewTOTPSecret creates a TOTP secret for an admin and the otpauth:// URL their
// authenticator app scans (A-01).
func NewTOTPSecret(account string) (secret, url string, err error) {
	key, err := totp.Generate(totp.GenerateOpts{Issuer: "PAO", AccountName: account})
	if err != nil {
		return "", "", fmt.Errorf("generate totp secret: %w", err)
	}
	return key.Secret(), key.URL(), nil
}

// ValidateTOTP checks a 6-digit code at time now, allowing one 30-second step of
// clock drift either way.
func ValidateTOTP(code, secret string, now time.Time) bool {
	ok, err := totp.ValidateCustom(code, secret, now, totp.ValidateOpts{
		Period: 30, Skew: 1, Digits: otp.DigitsSix, Algorithm: otp.AlgorithmSHA1,
	})
	return err == nil && ok
}

// TOTPCode returns the code for secret at now; used by tests and the e2e suite.
func TOTPCode(secret string, now time.Time) (string, error) {
	return totp.GenerateCode(secret, now)
}
