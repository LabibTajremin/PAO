package app

import (
	"context"
	"errors"
	"regexp"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

const phone = "01712345678"

var ctx = context.Background()

func (h *harness) sentCode(t *testing.T) string {
	t.Helper()
	m := regexp.MustCompile(`[0-9]{6}`).FindString(h.sms.last["+8801712345678"])
	if m == "" {
		t.Fatal("no code sent")
	}
	return m
}

func (h *harness) login(t *testing.T, app string) Session {
	t.Helper()
	if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin, ClientIP: "1.2.3.4"}); err != nil {
		t.Fatal(err)
	}
	s, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: h.sentCode(t), App: app})
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func TestVerifyLogin_CreatesAccountThenAddsPartnerRole(t *testing.T) {
	h := newHarness()
	first := h.login(t, "customer")
	if !first.IsNewAccount || first.Account.Roles[0] != "customer" || first.RefreshToken == "" || first.AccessToken == "" {
		t.Fatalf("first login: %+v", first)
	}
	if _, ok := h.repo.events[0].(contract.AccountCreated); !ok {
		t.Fatalf("event = %T", h.repo.events[0])
	}
	h.clock.Advance(domain.ResendAfter)
	second := h.login(t, "partner")
	if second.IsNewAccount || !second.Account.HasRole("provider") || second.Account.ID != first.Account.ID {
		t.Fatalf("second login: %+v", second)
	}
	if _, ok := h.repo.events[1].(contract.RoleGranted); !ok {
		t.Fatalf("event = %T", h.repo.events[1])
	}
	h.clock.Advance(domain.ResendAfter)
	if third := h.login(t, "partner"); len(h.repo.events) != 2 || third.IsNewAccount {
		t.Fatal("returning provider published an event")
	}
}

func TestSendCode_Refusals(t *testing.T) {
	h := newHarness()
	if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: "123"}); !errors.Is(err, domain.ErrInvalidPhone) {
		t.Fatalf("invalid phone: %v", err)
	}
	h.repo.blocked["+8801712345678"] = true
	if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin}); !errors.Is(err, domain.ErrAccountBanned) {
		t.Fatalf("blocked: %v", err)
	}
	if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeDeleteAccount}); err != nil {
		t.Fatalf("blocked phones still get non-login codes: %v", err)
	}
	h.repo.faults["IsPhoneBlocked"] = errBoom
	if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin}); !errors.Is(err, errBoom) {
		t.Fatalf("lookup failure: %v", err)
	}
	h = newHarness()
	h.limiter.blockKey = "pao:t:rl:otp:ip:9.9.9.9"
	_, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin, ClientIP: "9.9.9.9"})
	var rl *RateLimitError
	if !errors.As(err, &rl) || rl.RetryAfter.Seconds() != 42 || !errors.Is(err, domain.ErrRateLimited) || rl.Error() == "" {
		t.Fatalf("rate limit: %v", err)
	}
}

func TestSendCode_DependencyFailures(t *testing.T) {
	for _, tc := range []struct {
		name string
		set  func(h *harness)
	}{
		{"limiter", func(h *harness) { h.limiter.faults["Allow"] = errBoom }},
		{"store", func(h *harness) { h.codes.faults["Save"] = errBoom }},
		{"sms", func(h *harness) { h.sms.faults["Send"] = errBoom }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			h := newHarness()
			tc.set(h)
			if _, err := h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin}); !errors.Is(err, errBoom) {
				t.Fatalf("err = %v", err)
			}
		})
	}
}

func TestVerifyLogin_WrongCodesLockOut(t *testing.T) {
	h := newHarness()
	if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: "x"}); !errors.Is(err, domain.ErrInvalidPhone) {
		t.Fatal("invalid phone accepted")
	}
	if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: "000000"}); !errors.Is(err, domain.ErrCodeExpired) {
		t.Fatalf("no code sent: %v", err)
	}
	_, _ = h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin})
	wrong := "999999"
	if h.sentCode(t) == wrong {
		wrong = "999998"
	}
	for i := 1; i < domain.CodeMaxAttempts; i++ {
		if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: wrong}); !errors.Is(err, domain.ErrCodeInvalid) {
			t.Fatalf("attempt %d: %v", i, err)
		}
	}
	if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: wrong}); !errors.Is(err, domain.ErrCodeLocked) {
		t.Fatalf("lockout: %v", err)
	}
	if len(h.codes.codes) != 0 {
		t.Fatal("locked code not discarded")
	}
}

func TestVerifyLogin_CodeStoreFailures(t *testing.T) {
	for name, set := range map[string]func(h *harness){
		"get":       func(h *harness) { h.codes.faults["Get"] = errBoom },
		"increment": func(h *harness) { h.codes.faults["IncrementAttempts"] = errBoom },
		"malformed": func(h *harness) { h.codes.codes["pao:t:otp:login:+8801712345678"] = domain.StoredCode{Hash: "bad"} },
	} {
		t.Run(name, func(t *testing.T) {
			h := newHarness()
			_, _ = h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin})
			set(h)
			if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: "000000x"}); err == nil {
				t.Fatal("verify succeeded")
			}
		})
	}
}

func TestVerifyLogin_AccountFailures(t *testing.T) {
	cases := map[string]struct {
		set  func(h *harness)
		want error
	}{
		"lookup":  {func(h *harness) { h.repo.faults["AccountByPhone"] = errBoom }, errBoom},
		"create":  {func(h *harness) { h.repo.faults["CreateAccount"] = errBoom }, errBoom},
		"grant":   {func(h *harness) { h.repo.faults["GrantRole"] = errBoom }, errBoom},
		"publish": {func(h *harness) { h.repo.faults["Publish"] = errBoom }, errBoom},
		"version": {func(h *harness) { h.perms.faults["Version"] = errBoom }, errBoom},
		"sign":    {func(h *harness) { h.signer.faults["Sign"] = errBoom }, errBoom},
		"session": {func(h *harness) { h.sessions.faults["Save"] = errBoom }, errBoom},
		"delete":  {func(h *harness) { h.codes.faults["Delete"] = errBoom }, errBoom},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			h := newHarness()
			_, _ = h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin})
			tc.set(h)
			if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: h.sentCode(t), App: "customer"}); !errors.Is(err, tc.want) {
				t.Fatalf("err = %v", err)
			}
		})
	}
}

func TestVerifyLogin_ExistingAccountFailures(t *testing.T) {
	for name, set := range map[string]func(h *harness){
		"grant":   func(h *harness) { h.repo.faults["GrantRole"] = errBoom },
		"publish": func(h *harness) { h.repo.faults["Publish"] = errBoom },
	} {
		t.Run(name, func(t *testing.T) {
			h := newHarness()
			h.login(t, "customer")
			h.clock.Advance(domain.ResendAfter)
			_, _ = h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeLogin})
			set(h)
			if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: h.sentCode(t), App: "partner"}); !errors.Is(err, errBoom) {
				t.Fatalf("err = %v", err)
			}
		})
	}
}

func TestVerifyLogin_BannedAccountRefused(t *testing.T) {
	h := newHarness()
	s := h.login(t, "customer")
	a := h.repo.accounts[s.Account.ID]
	a.Status = domain.StatusBanned
	h.repo.accounts[a.ID] = a
	h.clock.Advance(domain.ResendAfter)
	_, _ = h.svc.SendCode(ctx, SendCodeInput{Phone: phone, Purpose: PurposeDeleteAccount})
	_ = h.svc.d.Codes.Save(ctx, "pao:t:otp:login:+8801712345678", h.codes.codes["pao:t:otp:delete_account:+8801712345678"], 0)
	if _, err := h.svc.VerifyLogin(ctx, VerifyLoginInput{Phone: phone, Code: h.sentCode(t), App: "partner"}); !errors.Is(err, domain.ErrAccountBanned) {
		t.Fatalf("banned: %v", err)
	}
}
