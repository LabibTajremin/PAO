// Package inproc implements the identity contract for other modules in the same
// process (PRD §9.3 rule 7).
package inproc

import (
	"context"
	"errors"
	"slices"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

// Service adapts the identity use cases to contract.IdentityService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.IdentityService = (*Service)(nil)

var contractErrors = map[error]error{
	domain.ErrAccountNotFound: contract.ErrAccountNotFound,
	domain.ErrCodeInvalid:     contract.ErrCodeInvalid,
	domain.ErrCodeExpired:     contract.ErrCodeExpired,
	domain.ErrCodeLocked:      contract.ErrCodeLocked,
	domain.ErrRateLimited:     contract.ErrRateLimited,
	domain.ErrStatusChange:    contract.ErrStatusInvalid,
}

// translate keeps the original error chain and adds the contract sentinel.
func translate(err error) error {
	for d, c := range contractErrors {
		if errors.Is(err, d) {
			return errors.Join(c, err)
		}
	}
	return err
}

// GetAccount implements contract.IdentityService.
func (s *Service) GetAccount(ctx context.Context, id uuid.UUID) (contract.Account, error) {
	a, err := s.svc.GetAccount(ctx, id)
	if err != nil {
		return contract.Account{}, translate(err)
	}
	return toContract(a), nil
}

// HasRole implements contract.IdentityService.
func (s *Service) HasRole(ctx context.Context, id uuid.UUID, role contract.Role) (bool, error) {
	a, err := s.svc.GetAccount(ctx, id)
	if err != nil {
		return false, translate(err)
	}
	return a.HasRole(string(role)), nil
}

// SetAccountStatus implements contract.IdentityService.
func (s *Service) SetAccountStatus(ctx context.Context, in contract.SetAccountStatusInput) (contract.Account, error) {
	a, err := s.svc.SetAccountStatus(ctx, in)
	if err != nil {
		return contract.Account{}, translate(err)
	}
	return toContract(a), nil
}

// SendPhoneCode implements contract.IdentityService.
func (s *Service) SendPhoneCode(ctx context.Context, phone string, purpose contract.CodePurpose) error {
	_, err := s.svc.SendCode(ctx, app.SendCodeInput{Phone: phone, Purpose: string(purpose), ClientIP: "internal"})
	return translate(err)
}

// CheckPhoneCode implements contract.IdentityService.
func (s *Service) CheckPhoneCode(ctx context.Context, phone string, purpose contract.CodePurpose, code string) error {
	return translate(s.svc.CheckPhoneCode(ctx, phone, string(purpose), code))
}

func toContract(a domain.Account) contract.Account {
	roles := make([]contract.Role, len(a.Roles))
	for i, r := range a.Roles {
		roles[i] = contract.Role(r)
	}
	slices.Sort(roles)
	return contract.Account{ID: a.ID, Phone: string(a.Phone), Email: a.Email, Roles: roles, Status: contract.AccountStatus(a.Status), CreatedAt: a.CreatedAt}
}
