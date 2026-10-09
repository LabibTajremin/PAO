package app

import (
	"errors"
	"slices"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

func TestPermissions_ProviderGate(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	if a, err := h.svc.GetAccount(ctx, s.Account.ID); err != nil || a.ID != s.Account.ID {
		t.Fatal("GetAccount")
	}
	v, err := h.svc.Permissions(ctx, s.Account.ID)
	if err != nil || v.ProviderGate || !slices.Equal(v.Screens, []string{"C01", "C07"}) {
		t.Fatalf("customer: %+v %v", v, err)
	}
	h.clock.Advance(domain.ResendAfter)
	h.login(t, "partner")
	v, _ = h.svc.Permissions(ctx, s.Account.ID)
	if !v.ProviderGate || !slices.Equal(v.Screens, []string{"C01", "C07", "M01", "M14"}) {
		t.Fatalf("level 0 provider: %+v", v)
	}
	h.levels.level = 1
	v, _ = h.svc.Permissions(ctx, s.Account.ID)
	if v.ProviderGate || !slices.Contains(v.Screens, "M15") {
		t.Fatalf("level 1 provider: %+v", v)
	}
	for name, set := range map[string]func(){
		"account": func() { h.repo.faults["AccountByID"] = errBoom },
		"grants":  func() { h.perms.faults["Grants"] = errBoom },
		"level":   func() { h.levels.faults["GetLevel"] = errBoom },
	} {
		h.repo.faults, h.perms.faults, h.levels.faults = faults{}, faults{}, faults{}
		set()
		if _, err := h.svc.Permissions(ctx, s.Account.ID); !errors.Is(err, errBoom) {
			t.Errorf("%s: %v", name, err)
		}
	}
}

func (h *harness) deletionCode(t *testing.T) string {
	t.Helper()
	h.clock.Advance(domain.ResendAfter)
	if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeDeleteAccount}); err != nil {
		t.Fatal(err)
	}
	return h.sentCode(t)
}

func TestDeleteAccount(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	c := callerOf(t, h, s)
	if err := h.svc.DeleteAccount(ctx, c, h.deletionCode(t)); err != nil {
		t.Fatal(err)
	}
	a := h.repo.accounts[s.Account.ID]
	if a.Phone != "" || a.DeletedAt == nil || len(a.Roles) != 0 || len(h.sessions.families) != 0 {
		t.Fatalf("not erased: %+v", a)
	}
	if _, ok := h.repo.events[len(h.repo.events)-1].(contract.AccountDeleted); !ok {
		t.Fatal("AccountDeleted not published")
	}
	if err := h.svc.DeleteAccount(ctx, c, "123456"); !errors.Is(err, domain.ErrAccountDeleted) {
		t.Fatalf("second deletion: %v", err)
	}
	if err := h.svc.DeleteAccount(ctx, Caller{AccountID: uuid.New()}, "1"); !errors.Is(err, domain.ErrAccountNotFound) {
		t.Fatal("unknown account")
	}
}

func TestDeleteAccount_Failures(t *testing.T) {
	for _, step := range []string{"SetRoles", "AnonymiseAccount", "code"} {
		h := newHarness()
		s := h.login(t, "customer")
		code := h.deletionCode(t)
		if step == "code" {
			code = "x"
		}
		h.repo.faults[step] = errBoom
		if err := h.svc.DeleteAccount(ctx, callerOf(t, h, s), code); err == nil {
			t.Errorf("%s: deletion succeeded", step)
		}
	}
}

func TestCheckPhoneCode(t *testing.T) {
	h := newHarness()
	if err := h.svc.CheckPhoneCode(ctx, "bad", PurposeEmergencyContact, "1"); !errors.Is(err, domain.ErrInvalidPhone) {
		t.Fatal("bad phone")
	}
	_, _ = h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeEmergencyContact})
	if err := h.svc.CheckPhoneCode(ctx, phone, PurposeEmergencyContact, h.sentCode(t)); err != nil {
		t.Fatal(err)
	}
}
