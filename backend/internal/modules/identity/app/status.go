package app

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
)

// SetAccountStatus suspends, bans or reinstates an account (A-05). Banning blocks the
// phone so it cannot sign up again (PRD §6.4); suspending or banning ends sessions.
func (s *Service) SetAccountStatus(ctx context.Context, in contract.SetAccountStatusInput) (domain.Account, error) {
	a, err := s.d.Repo.AccountByID(ctx, in.AccountID)
	if err != nil {
		return domain.Account{}, err
	}
	to := domain.Status(in.Status)
	if err := a.ChangeStatus(to); err != nil {
		return domain.Account{}, err
	}
	from := a.Status
	err = s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		if err := tx.UpdateStatus(ctx, a.ID, to); err != nil {
			return err
		}
		if err := s.updatePhoneBlock(ctx, tx, a, to, in.Reason); err != nil {
			return err
		}
		return tx.Publish(ctx, a.ID.String(), contract.AccountStatusChanged{
			AccountID: a.ID, From: contract.AccountStatus(from), To: contract.AccountStatus(to),
			Reason: in.Reason, ActorID: in.ActorID, Roles: toContractRoles(a.Roles),
		})
	})
	if err != nil {
		return domain.Account{}, err
	}
	a.Status = to
	if to != domain.StatusActive {
		return a, s.revokeAll(ctx, a.ID)
	}
	return a, nil
}

func (s *Service) updatePhoneBlock(ctx context.Context, tx port.TxRepository, a domain.Account, to domain.Status, reason string) error {
	switch {
	case a.Phone == "":
		return nil
	case to == domain.StatusBanned:
		return tx.BlockPhone(ctx, a.Phone, reason)
	case a.Status == domain.StatusBanned:
		return tx.UnblockPhone(ctx, a.Phone)
	}
	return nil
}

func toContractRoles(roles []string) []contract.Role {
	out := make([]contract.Role, len(roles))
	for i, r := range roles {
		out[i] = contract.Role(r)
	}
	return out
}
