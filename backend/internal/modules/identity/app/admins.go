package app

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
)

// CreateAdminInput invites an admin.
type CreateAdminInput struct {
	Email string
	Name  string
	Roles []string
}

// CreateAdmin creates an admin with a one-time temporary password; the first login
// forces a password change and TOTP enrolment (A-01).
func (s *Service) CreateAdmin(ctx context.Context, in CreateAdminInput) (domain.Admin, string, error) {
	if !domain.IsAdminRoleSet(in.Roles) {
		return domain.Admin{}, "", domain.ErrRoleInvalid
	}
	email := strings.ToLower(strings.TrimSpace(in.Email))
	switch _, err := s.d.Repo.AdminByEmail(ctx, email); {
	case err == nil:
		return domain.Admin{}, "", domain.ErrEmailTaken
	case !errors.Is(err, domain.ErrAccountNotFound):
		return domain.Admin{}, "", err
	}
	temp := auth.RandomToken(12)
	admin := domain.Admin{
		Account: domain.Account{ID: s.d.IDs.New(), Email: email, Name: in.Name, Status: domain.StatusActive,
			Roles: in.Roles, CreatedAt: s.d.Clock.Now()},
		PasswordHash: auth.Hash(temp, auth.PasswordParams), MustChangePassword: true, Active: true,
	}
	err := s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		if err := tx.CreateAccount(ctx, admin.Account); err != nil {
			return err
		}
		if err := tx.SetRoles(ctx, admin.ID, in.Roles); err != nil {
			return err
		}
		return tx.CreateAdminCredentials(ctx, admin.ID, admin.PasswordHash)
	})
	if err != nil {
		return domain.Admin{}, "", err
	}
	return admin, temp, nil
}

// UpdateAdminInput changes roles and/or the active flag.
type UpdateAdminInput struct {
	AdminID uuid.UUID
	Roles   []string
	Active  *bool
}

// UpdateAdmin changes an admin and ends their sessions so new rights apply at once.
func (s *Service) UpdateAdmin(ctx context.Context, in UpdateAdminInput) (domain.Admin, error) {
	if in.Roles != nil && !domain.IsAdminRoleSet(in.Roles) {
		return domain.Admin{}, domain.ErrRoleInvalid
	}
	admin, err := s.d.Repo.AdminByID(ctx, in.AdminID)
	if err != nil {
		return domain.Admin{}, err
	}
	if in.Active != nil {
		admin.Active = *in.Active
	}
	err = s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		if in.Roles != nil {
			admin.Roles = in.Roles
			if err := tx.SetRoles(ctx, admin.ID, in.Roles); err != nil {
				return err
			}
		}
		return tx.SaveAdmin(ctx, admin)
	})
	if err != nil {
		return domain.Admin{}, err
	}
	return admin, s.revokeAll(ctx, admin.ID)
}

// ListAdmins returns every admin.
func (s *Service) ListAdmins(ctx context.Context) ([]domain.Admin, error) {
	return s.d.Repo.ListAdmins(ctx)
}

// EnsureAdmin creates a demo admin with a known password unless the email exists; used
// by the seed for dev and staging. TOTP enrolment still happens at first login.
func (s *Service) EnsureAdmin(ctx context.Context, in CreateAdminInput, password string) error {
	if _, err := s.d.Repo.AdminByEmail(ctx, strings.ToLower(in.Email)); !errors.Is(err, domain.ErrAccountNotFound) {
		return err
	}
	admin, _, err := s.CreateAdmin(ctx, in)
	if err != nil {
		return err
	}
	admin.PasswordHash, admin.MustChangePassword = auth.Hash(password, auth.PasswordParams), false
	return s.saveAdmin(ctx, admin)
}
