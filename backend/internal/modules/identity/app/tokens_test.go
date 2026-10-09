package app

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

func callerOf(t *testing.T, h *harness, s Session) Caller {
	t.Helper()
	for _, f := range h.sessions.families {
		if f.AccountID == s.Account.ID && f.AccessJTI != "" {
			return Caller{AccountID: s.Account.ID, SessionID: f.ID, TokenID: f.AccessJTI, ExpiresAt: f.AccessExp}
		}
	}
	t.Fatal("no session")
	return Caller{}
}

func TestRefresh_RotatesAndDetectsReuse(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	next, err := h.svc.Refresh(ctx, s.RefreshToken)
	if err != nil || next.RefreshToken == s.RefreshToken || next.AccessToken == "" {
		t.Fatalf("refresh: %v", err)
	}
	if _, err := h.svc.Refresh(ctx, s.RefreshToken); !errors.Is(err, domain.ErrRefreshReused) {
		t.Fatalf("reuse: %v", err)
	}
	if len(h.sessions.families) != 0 || len(h.deny.denied) != 1 {
		t.Fatal("reuse did not revoke the family")
	}
	if _, err := h.svc.Refresh(ctx, next.RefreshToken); !errors.Is(err, domain.ErrRefreshInvalid) {
		t.Fatalf("revoked family refreshed: %v", err)
	}
}

func TestRefresh_Refusals(t *testing.T) {
	h := newHarness()
	if _, err := h.svc.Refresh(ctx, "garbage"); !errors.Is(err, domain.ErrRefreshInvalid) {
		t.Fatal("garbage accepted")
	}
	s := h.login(t, "customer")
	h.repo.faults["AccountByID"] = errBoom
	if _, err := h.svc.Refresh(ctx, s.RefreshToken); !errors.Is(err, errBoom) {
		t.Fatal("lookup failure hidden")
	}
	delete(h.repo.faults, "AccountByID")
	a := h.repo.accounts[s.Account.ID]
	a.Status = domain.StatusSuspended
	h.repo.accounts[a.ID] = a
	if _, err := h.svc.Refresh(ctx, s.RefreshToken); !errors.Is(err, domain.ErrAccountSuspended) || len(h.sessions.families) != 0 {
		t.Fatalf("suspended account refreshed: %v", err)
	}
}

func TestLogout(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	h.clock.Advance(domain.ResendAfter)
	other := h.login(t, "customer")
	if err := h.svc.Logout(ctx, callerOf(t, h, s), false); err != nil {
		t.Fatal(err)
	}
	if len(h.sessions.families) != 1 {
		t.Fatalf("families left = %d", len(h.sessions.families))
	}
	if err := h.svc.Logout(ctx, Caller{AccountID: s.Account.ID, SessionID: uuid.New()}, false); err != nil {
		t.Fatalf("unknown session: %v", err)
	}
	if err := h.svc.Logout(ctx, callerOf(t, h, other), true); err != nil || len(h.sessions.families) != 0 {
		t.Fatalf("all devices: %v", err)
	}
}

func TestLogout_Failures(t *testing.T) {
	for name, set := range map[string]func(h *harness){
		"deny":   func(h *harness) { h.deny.faults["Deny"] = errBoom },
		"get":    func(h *harness) { h.sessions.faults["Get"] = errBoom },
		"list":   func(h *harness) { h.sessions.faults["ListForAccount"] = errBoom },
		"delete": func(h *harness) { h.sessions.faults["Delete"] = errBoom },
	} {
		t.Run(name, func(t *testing.T) {
			h := newHarness()
			c := callerOf(t, h, h.login(t, "customer"))
			set(h)
			err := errors.Join(h.svc.Logout(ctx, c, false), h.svc.Logout(ctx, c, true))
			if !errors.Is(err, errBoom) {
				t.Fatalf("err = %v", err)
			}
		})
	}
}

func TestEndSession_Failures(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	_, _ = h.svc.Refresh(ctx, s.RefreshToken)
	h.deny.faults["Deny"] = errBoom
	if _, err := h.svc.Refresh(ctx, s.RefreshToken); !errors.Is(err, errBoom) || !errors.Is(err, domain.ErrRefreshReused) {
		t.Fatalf("reuse with denylist down: %v", err)
	}
	h = newHarness()
	c := callerOf(t, h, h.login(t, "customer"))
	h.sessions.faults["Delete"] = errBoom
	if err := h.svc.Logout(ctx, c, true); !errors.Is(err, errBoom) {
		t.Fatalf("revoke all: %v", err)
	}
}
