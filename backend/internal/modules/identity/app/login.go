package app

import (
	"context"
	"errors"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
)

// VerifyLoginInput completes a phone sign-in.
type VerifyLoginInput struct {
	Phone string
	Code  string
	// App is "customer" or "partner"; the partner app grants the provider role.
	App string
}

// VerifyLogin checks the code, creates the account on first sign-in or adds the app's
// role, and opens a session (C-01, P-01).
func (s *Service) VerifyLogin(ctx context.Context, in VerifyLoginInput) (Session, error) {
	phone, err := domain.NormalizePhone(in.Phone)
	if err != nil {
		return Session{}, err
	}
	if err := s.checkCode(ctx, PurposeLogin, phone, in.Code); err != nil {
		return Session{}, err
	}
	account, isNew, err := s.loadOrCreate(ctx, phone, domain.RoleForApp(in.App))
	if err != nil {
		return Session{}, err
	}
	if err := account.CanSignIn(); err != nil {
		return Session{}, err
	}
	sess, err := s.openSession(ctx, account, in.App)
	sess.IsNewAccount = isNew
	return sess, err
}

func (s *Service) loadOrCreate(ctx context.Context, phone domain.Phone, role string) (domain.Account, bool, error) {
	account, err := s.d.Repo.AccountByPhone(ctx, phone)
	if errors.Is(err, domain.ErrAccountNotFound) {
		account = domain.Account{ID: s.d.IDs.New(), Phone: phone, Status: domain.StatusActive, Roles: []string{role}, CreatedAt: s.d.Clock.Now()}
		err = s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
			if err := tx.CreateAccount(ctx, account); err != nil {
				return err
			}
			if err := tx.GrantRole(ctx, account.ID, role); err != nil {
				return err
			}
			return tx.Publish(ctx, account.ID.String(), contract.AccountCreated{AccountID: account.ID, Phone: string(phone), Role: contract.Role(role)})
		})
		return account, true, err
	}
	if err != nil || account.HasRole(role) || account.CanSignIn() != nil {
		return account, false, err
	}
	err = s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		if err := tx.GrantRole(ctx, account.ID, role); err != nil {
			return err
		}
		return tx.Publish(ctx, account.ID.String(), contract.RoleGranted{AccountID: account.ID, Role: contract.Role(role)})
	})
	account.Roles = append(account.Roles, role)
	return account, false, err
}
