package app

import (
	"context"
	"errors"
	"slices"
	"strings"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
)

// GetAccount returns an account.
func (s *Service) GetAccount(ctx context.Context, id uuid.UUID) (domain.Account, error) {
	return s.d.Repo.AccountByID(ctx, id)
}

// PermissionsView is GET /v1/me/permissions.
type PermissionsView struct {
	Roles        []string
	Permissions  []string
	Screens      []string
	ProviderGate bool
}

// Permissions resolves the account's grants. A provider below Level 1 only sees the
// onboarding and verification screens (PRD §8.5).
func (s *Service) Permissions(ctx context.Context, accountID uuid.UUID) (PermissionsView, error) {
	a, err := s.d.Repo.AccountByID(ctx, accountID)
	if err != nil {
		return PermissionsView{}, err
	}
	g, err := s.d.Permissions.Grants(ctx, a.Roles)
	if err != nil {
		return PermissionsView{}, err
	}
	view := PermissionsView{Roles: a.Roles, Permissions: g.Permissions, Screens: g.Screens}
	if !a.HasRole(domain.RoleProvider) {
		return view, nil
	}
	level, err := s.d.Levels.GetLevel(ctx, accountID)
	if err != nil || level >= 1 {
		return view, err
	}
	view.ProviderGate = true
	view.Screens = slices.DeleteFunc(view.Screens, func(id string) bool {
		return strings.HasPrefix(id, "M") && !slices.Contains(domain.ProviderGateScreens, id)
	})
	return view, nil
}

// DeleteAccount erases the caller's identity after re-confirming with an OTP:
// sessions end, personal data is anonymised and AccountDeleted tells the other
// modules to erase theirs (PRD §11).
func (s *Service) DeleteAccount(ctx context.Context, c Caller, code string) error {
	a, err := s.d.Repo.AccountByID(ctx, c.AccountID)
	if err != nil {
		return err
	}
	if a.Phone == "" {
		return domain.ErrAccountDeleted
	}
	if err := s.checkCode(ctx, PurposeDeleteAccount, a.Phone, code); err != nil {
		return err
	}
	err = s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		if err := tx.SetRoles(ctx, a.ID, nil); err != nil {
			return err
		}
		if err := tx.AnonymiseAccount(ctx, a.ID); err != nil {
			return err
		}
		return tx.Publish(ctx, a.ID.String(), contract.AccountDeleted{AccountID: a.ID})
	})
	return errors.Join(err, s.revokeAll(ctx, a.ID))
}
