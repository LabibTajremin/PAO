package app

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
)

// Code purposes; a code sent for one purpose never satisfies another.
const (
	PurposeLogin            = "login"
	PurposeDeleteAccount    = "delete_account"
	PurposeEmergencyContact = "emergency_contact"
)

// RateLimitError carries how long the caller must wait.
type RateLimitError struct{ RetryAfter time.Duration }

func (e *RateLimitError) Error() string { return "rate limited for " + e.RetryAfter.String() }

// Unwrap lets callers match domain.ErrRateLimited.
func (e *RateLimitError) Unwrap() error { return domain.ErrRateLimited }

// SendCodeInput asks for a one-time code by SMS.
type SendCodeInput struct {
	Phone    string
	Purpose  string
	ClientIP string
}

// SendCode rate-limits, stores the hash of a fresh 6-digit code and texts it.
func (s *Service) SendCode(ctx context.Context, in SendCodeInput) (domain.Phone, error) {
	phone, err := domain.NormalizePhone(in.Phone)
	if err != nil {
		return "", err
	}
	if in.Purpose == PurposeLogin {
		if err := s.refuseBlocked(ctx, phone); err != nil {
			return "", err
		}
	}
	if err := s.throttleSends(ctx, phone, in.ClientIP); err != nil {
		return "", err
	}
	code := auth.RandomDigits(domain.CodeLength)
	key := s.codeKey(in.Purpose, phone)
	if err := s.d.Codes.Save(ctx, key, domain.StoredCode{Hash: auth.Hash(code, auth.CodeParams)}, domain.CodeTTL); err != nil {
		return "", err
	}
	msg := fmt.Sprintf("PAO code: %s. Valid for 5 minutes. Never share it. / আপনার PAO কোড %s", code, code)
	if err := s.d.SMS.Send(ctx, phone, msg); err != nil {
		return "", fmt.Errorf("send code to %s: %w", phone.Masked(), err)
	}
	return phone, nil
}

// refuseBlocked stops codes to banned identities before an SMS is paid for.
func (s *Service) refuseBlocked(ctx context.Context, phone domain.Phone) error {
	blocked, err := s.d.Repo.IsPhoneBlocked(ctx, phone)
	if err != nil {
		return err
	}
	if blocked {
		return domain.ErrAccountBanned
	}
	return nil
}

// throttleSends applies the resend timer and the per-phone and per-IP windows.
func (s *Service) throttleSends(ctx context.Context, phone domain.Phone, ip string) error {
	limits := []struct {
		key    string
		limit  int
		window time.Duration
	}{
		{s.d.Keys.Key("rl", "otp", "resend", string(phone)), 1, domain.ResendAfter},
		{s.d.Keys.Key("rl", "otp", "phone", string(phone)), domain.SendsPerPhone, domain.SendWindowPhone},
		{s.d.Keys.Key("rl", "otp", "ip", ip), domain.SendsPerIP, domain.SendWindowIP},
	}
	for _, l := range limits {
		d, err := s.d.Limiter.Allow(ctx, l.key, l.limit, l.window)
		if err != nil {
			return err
		}
		if !d.Allowed {
			return &RateLimitError{RetryAfter: d.RetryAfter}
		}
	}
	return nil
}

// checkCode verifies a code and consumes it on success or lockout.
func (s *Service) checkCode(ctx context.Context, purpose string, phone domain.Phone, code string) error {
	key := s.codeKey(purpose, phone)
	stored, err := s.d.Codes.Get(ctx, key)
	if err != nil {
		return err
	}
	matched, err := auth.VerifyHash(code, stored.Hash)
	if err != nil {
		return err
	}
	discard, outcome := stored.CheckAttempt(matched)
	if discard {
		err = s.d.Codes.Delete(ctx, key)
	} else {
		err = s.d.Codes.IncrementAttempts(ctx, key)
	}
	return errors.Join(outcome, err)
}

func (s *Service) codeKey(purpose string, phone domain.Phone) string {
	return s.d.Keys.Key("otp", purpose, string(phone))
}
