package app

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
)

// Session is what a successful sign-in or refresh returns.
type Session struct {
	AccessToken  string
	RefreshToken string
	ExpiresIn    time.Duration
	Account      domain.Account
	IsNewAccount bool
}

// Caller identifies the signed-in device making a request.
type Caller struct {
	AccountID uuid.UUID
	SessionID uuid.UUID
	TokenID   string
	ExpiresAt time.Time
}

// openSession starts a new refresh-token family for the device.
func (s *Service) openSession(ctx context.Context, a domain.Account, app string) (Session, error) {
	return s.issue(ctx, a, domain.Family{ID: s.d.IDs.New(), AccountID: a.ID, App: app})
}

// issue rotates the family's refresh secret and signs a new access token.
func (s *Service) issue(ctx context.Context, a domain.Account, f domain.Family) (Session, error) {
	version, err := s.d.Permissions.Version(ctx)
	if err != nil {
		return Session{}, err
	}
	access, claims, err := s.d.Signer.Sign(auth.Claims{Subject: a.ID, Roles: a.Roles, SessionID: f.ID, Version: version})
	if err != nil {
		return Session{}, err
	}
	secret := auth.RandomToken(32)
	f.CurrentHash, f.AccessJTI, f.AccessExp = auth.SHA256Hex(secret), claims.ID, claims.ExpiresAt
	if err := s.d.Sessions.Save(ctx, f, domain.RefreshTTL); err != nil {
		return Session{}, err
	}
	return Session{AccessToken: access, RefreshToken: domain.FormatRefreshToken(f.ID, secret), ExpiresIn: domain.AccessTTL, Account: a}, nil
}

// Refresh exchanges a refresh token for a new pair. Presenting an already rotated
// token revokes the whole family: someone else has a copy (02-architecture §5).
func (s *Service) Refresh(ctx context.Context, token string) (Session, error) {
	familyID, secret, err := domain.ParseRefreshToken(token)
	if err != nil {
		return Session{}, err
	}
	f, err := s.d.Sessions.Get(ctx, familyID)
	if err != nil {
		return Session{}, err
	}
	if !f.Matches(auth.SHA256Hex(secret)) {
		return Session{}, errors.Join(domain.ErrRefreshReused, s.endSession(ctx, f))
	}
	a, err := s.d.Repo.AccountByID(ctx, f.AccountID)
	if err != nil {
		return Session{}, err
	}
	if err := a.CanSignIn(); err != nil {
		return Session{}, errors.Join(err, s.endSession(ctx, f))
	}
	return s.issue(ctx, a, f)
}

// Logout ends the caller's session, or every session of the account.
func (s *Service) Logout(ctx context.Context, c Caller, allDevices bool) error {
	if err := s.d.Denylist.Deny(ctx, c.TokenID, c.ExpiresAt.Sub(s.d.Clock.Now())); err != nil {
		return err
	}
	if allDevices {
		return s.revokeAll(ctx, c.AccountID)
	}
	f, err := s.d.Sessions.Get(ctx, c.SessionID)
	if errors.Is(err, domain.ErrRefreshInvalid) {
		return nil
	}
	if err != nil {
		return err
	}
	return s.endSession(ctx, f)
}

// revokeAll ends every session of an account (ban, suspension, deletion, role change).
func (s *Service) revokeAll(ctx context.Context, accountID uuid.UUID) error {
	families, err := s.d.Sessions.ListForAccount(ctx, accountID)
	if err != nil {
		return err
	}
	for _, f := range families {
		if err := s.endSession(ctx, f); err != nil {
			return err
		}
	}
	return nil
}

func (s *Service) endSession(ctx context.Context, f domain.Family) error {
	if err := s.d.Denylist.Deny(ctx, f.AccessJTI, f.AccessExp.Sub(s.d.Clock.Now())); err != nil {
		return err
	}
	return s.d.Sessions.Delete(ctx, f)
}
