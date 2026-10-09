package app

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
)

// AdminChallenge is the first admin login step's result.
type AdminChallenge struct {
	ID                 string
	EnrolSecret        string
	EnrolURL           string
	MustChangePassword bool
}

// AdminLogin checks email and password and starts the TOTP step (A-01). Wrong
// passwords count towards a 15-minute lockout.
func (s *Service) AdminLogin(ctx context.Context, email, password string) (AdminChallenge, error) {
	admin, err := s.d.Repo.AdminByEmail(ctx, email)
	if errors.Is(err, domain.ErrAccountNotFound) {
		return AdminChallenge{}, domain.ErrInvalidCredentials
	}
	if err != nil {
		return AdminChallenge{}, err
	}
	now := s.d.Clock.Now()
	if err := admin.CheckCanLogin(now); err != nil {
		return AdminChallenge{}, err
	}
	ok, err := auth.VerifyHash(password, admin.PasswordHash)
	if err != nil {
		return AdminChallenge{}, err
	}
	if !ok {
		admin.RecordFailure(now)
		return AdminChallenge{}, errors.Join(domain.ErrInvalidCredentials, s.saveAdmin(ctx, admin))
	}
	admin.RecordSuccess()
	if err := s.saveAdmin(ctx, admin); err != nil {
		return AdminChallenge{}, err
	}
	return s.startChallenge(ctx, admin)
}

func (s *Service) startChallenge(ctx context.Context, admin domain.Admin) (AdminChallenge, error) {
	out := AdminChallenge{ID: s.d.IDs.New().String(), MustChangePassword: admin.MustChangePassword}
	ch := domain.Challenge{ID: out.ID, AdminID: admin.ID}
	if !admin.TOTPEnrolled {
		secret, url, err := auth.NewTOTPSecret(admin.Email)
		if err != nil {
			return AdminChallenge{}, err
		}
		ch.EnrolSecret, out.EnrolSecret, out.EnrolURL = secret, secret, url
	}
	return out, s.d.Challenges.Save(ctx, ch, domain.ChallengeTTL)
}

// AdminVerifyTOTP completes an admin login with an authenticator code. On first login
// the code confirms enrolment and the secret is stored encrypted.
func (s *Service) AdminVerifyTOTP(ctx context.Context, challengeID, code string) (Session, error) {
	ch, err := s.d.Challenges.Get(ctx, challengeID)
	if err != nil {
		return Session{}, err
	}
	admin, err := s.d.Repo.AdminByID(ctx, ch.AdminID)
	if err != nil {
		return Session{}, err
	}
	secret, err := s.totpSecret(admin, ch)
	if err != nil {
		return Session{}, err
	}
	if !auth.ValidateTOTP(code, secret, s.d.Clock.Now()) {
		return Session{}, s.failChallenge(ctx, ch)
	}
	if err := s.d.Challenges.Delete(ctx, ch.ID); err != nil {
		return Session{}, err
	}
	now := s.d.Clock.Now()
	admin.LastLoginAt = &now
	if ch.EnrolSecret != "" {
		admin.TOTPSecretEnc, admin.TOTPEnrolled = s.d.Secrets.Encrypt([]byte(secret)), true
	}
	if err := s.saveAdmin(ctx, admin); err != nil {
		return Session{}, err
	}
	return s.openSession(ctx, admin.Account, "admin")
}

func (s *Service) totpSecret(admin domain.Admin, ch domain.Challenge) (string, error) {
	if ch.EnrolSecret != "" {
		return ch.EnrolSecret, nil
	}
	plain, err := s.d.Secrets.Decrypt(admin.TOTPSecretEnc)
	return string(plain), err
}

func (s *Service) failChallenge(ctx context.Context, ch domain.Challenge) error {
	ch.Attempts++
	if ch.Attempts >= domain.ChallengeAttempts {
		return errors.Join(domain.ErrChallengeExpired, s.d.Challenges.Delete(ctx, ch.ID))
	}
	return errors.Join(domain.ErrTOTPInvalid, s.d.Challenges.Save(ctx, ch, domain.ChallengeTTL))
}

// ChangeAdminPassword replaces the password after checking the current one.
func (s *Service) ChangeAdminPassword(ctx context.Context, accountID uuid.UUID, current, next string) error {
	admin, err := s.d.Repo.AdminByID(ctx, accountID)
	if err != nil {
		return err
	}
	ok, err := auth.VerifyHash(current, admin.PasswordHash)
	if err != nil {
		return err
	}
	if !ok {
		return domain.ErrInvalidCredentials
	}
	if err := domain.ValidatePassword(next); err != nil {
		return err
	}
	admin.PasswordHash, admin.MustChangePassword = auth.Hash(next, auth.PasswordParams), false
	return s.saveAdmin(ctx, admin)
}

func (s *Service) saveAdmin(ctx context.Context, a domain.Admin) error {
	return s.d.Repo.InTx(ctx, func(tx port.TxRepository) error { return tx.SaveAdmin(ctx, a) })
}
