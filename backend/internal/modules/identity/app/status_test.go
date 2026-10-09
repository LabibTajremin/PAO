package app

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

func TestSetAccountStatus_BanAndReinstate(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	actor := uuid.New()
	a, err := h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: s.Account.ID, Status: contract.StatusBanned, Reason: "fraud", ActorID: actor})
	if err != nil || a.Status != domain.StatusBanned || !h.repo.blocked["+8801712345678"] || len(h.sessions.families) != 0 {
		t.Fatalf("ban: %+v %v", a, err)
	}
	ev := h.repo.events[len(h.repo.events)-1].(contract.AccountStatusChanged)
	if ev.From != contract.StatusActive || ev.To != contract.StatusBanned || ev.ActorID != actor || ev.Roles[0] != contract.RoleCustomer {
		t.Fatalf("event: %+v", ev)
	}
	if _, err := h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: s.Account.ID, Status: contract.StatusActive, Reason: "appeal"}); err != nil || h.repo.blocked["+8801712345678"] {
		t.Fatalf("reinstate: %v", err)
	}
	if _, err := h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: s.Account.ID, Status: contract.StatusActive}); !errors.Is(err, domain.ErrStatusChange) {
		t.Fatal("no-op change accepted")
	}
	if _, err := h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: s.Account.ID, Status: contract.StatusSuspended}); err != nil {
		t.Fatal(err)
	}
}

func TestSetAccountStatus_AdminWithoutPhone(t *testing.T) {
	h := newHarness()
	a, _ := h.newAdmin(t)
	h.repo.accounts[a.ID] = a.Account
	if _, err := h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: a.ID, Status: contract.StatusBanned}); err != nil {
		t.Fatal(err)
	}
}

func TestSetAccountStatus_Failures(t *testing.T) {
	for _, step := range []string{"AccountByID", "UpdateStatus", "BlockPhone", "Publish", "ListForAccount", "UnblockPhone"} {
		h := newHarness()
		s := h.login(t, "customer")
		if step == "UnblockPhone" {
			_, _ = h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: s.Account.ID, Status: contract.StatusBanned})
		}
		h.repo.faults[step] = errBoom
		h.sessions.faults[step] = errBoom
		to := contract.StatusBanned
		if step == "UnblockPhone" {
			to = contract.StatusActive
		}
		if _, err := h.svc.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: s.Account.ID, Status: to}); !errors.Is(err, errBoom) {
			t.Errorf("%s: %v", step, err)
		}
	}
}
