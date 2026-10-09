package app

import (
	"errors"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
)

func (h *harness) newAdmin(t *testing.T) (domain.Admin, string) {
	t.Helper()
	a, pw, err := h.svc.CreateAdmin(ctx, CreateAdminInput{Email: " Verifier@PAO.bd ", Name: "V", Roles: []string{"verifier"}})
	if err != nil {
		t.Fatal(err)
	}
	return a, pw
}

func (h *harness) totp(t *testing.T, secret string) string {
	t.Helper()
	code, err := auth.TOTPCode(secret, h.clock.Now())
	if err != nil {
		t.Fatal(err)
	}
	return code
}

func TestAdminLogin_EnrolThenLogin(t *testing.T) {
	h := newHarness()
	a, pw := h.newAdmin(t)
	ch, err := h.svc.AdminLogin(ctx, "verifier@pao.bd", pw)
	if err != nil || ch.EnrolSecret == "" || !ch.MustChangePassword || ch.EnrolURL == "" {
		t.Fatalf("first step: %+v %v", ch, err)
	}
	s, err := h.svc.AdminVerifyTOTP(ctx, ch.ID, h.totp(t, ch.EnrolSecret))
	if err != nil || s.Account.ID != a.ID || !h.repo.admins[a.ID].TOTPEnrolled {
		t.Fatalf("second step: %v", err)
	}
	if err := h.svc.ChangeAdminPassword(ctx, a.ID, pw, "a much longer passphrase 1"); err != nil {
		t.Fatal(err)
	}
	ch2, err := h.svc.AdminLogin(ctx, "verifier@pao.bd", "a much longer passphrase 1")
	if err != nil || ch2.EnrolSecret != "" || ch2.MustChangePassword {
		t.Fatalf("returning admin: %+v %v", ch2, err)
	}
	if _, err := h.svc.AdminVerifyTOTP(ctx, ch2.ID, h.totp(t, ch.EnrolSecret)); err != nil {
		t.Fatalf("stored secret: %v", err)
	}
}

func TestAdminLogin_WrongPasswordsLockOut(t *testing.T) {
	h := newHarness()
	h.newAdmin(t)
	if _, err := h.svc.AdminLogin(ctx, "nobody@pao.bd", "x"); !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatal("unknown email")
	}
	for i := 0; i < domain.AdminMaxFailures; i++ {
		if _, err := h.svc.AdminLogin(ctx, "verifier@pao.bd", "wrong"); !errors.Is(err, domain.ErrInvalidCredentials) {
			t.Fatalf("attempt %d: %v", i, err)
		}
	}
	if _, err := h.svc.AdminLogin(ctx, "verifier@pao.bd", "wrong"); !errors.Is(err, domain.ErrAdminLocked) {
		t.Fatalf("not locked: %v", err)
	}
}

func TestAdminLogin_Failures(t *testing.T) {
	cases := map[string]func(h *harness, a domain.Admin){
		"lookup":    func(h *harness, _ domain.Admin) { h.repo.faults["AdminByEmail"] = errBoom },
		"bad hash":  func(h *harness, a domain.Admin) { a.PasswordHash = "x"; h.repo.admins[a.ID] = a },
		"save":      func(h *harness, _ domain.Admin) { h.repo.faults["SaveAdmin"] = errBoom },
		"challenge": func(h *harness, _ domain.Admin) { h.challenges.faults["Save"] = errBoom },
		"totp email": func(h *harness, a domain.Admin) {
			a.Email = ""
			h.repo.admins[a.ID] = a
			h.repo.faults["AdminByEmail"] = nil
		},
	}
	for name, set := range cases {
		t.Run(name, func(t *testing.T) {
			h := newHarness()
			a, pw := h.newAdmin(t)
			set(h, h.repo.admins[a.ID])
			email := "verifier@pao.bd"
			if name == "totp email" {
				email = ""
			}
			if _, err := h.svc.AdminLogin(ctx, email, pw); err == nil {
				t.Fatal("login succeeded")
			}
		})
	}
}

func TestAdminVerifyTOTP_Failures(t *testing.T) {
	h := newHarness()
	a, pw := h.newAdmin(t)
	if _, err := h.svc.AdminVerifyTOTP(ctx, "missing", "123456"); !errors.Is(err, domain.ErrChallengeExpired) {
		t.Fatal("missing challenge")
	}
	ch, _ := h.svc.AdminLogin(ctx, "verifier@pao.bd", pw)
	for i := 1; i < domain.ChallengeAttempts; i++ {
		if _, err := h.svc.AdminVerifyTOTP(ctx, ch.ID, "000000"); !errors.Is(err, domain.ErrTOTPInvalid) {
			t.Fatalf("attempt %d: %v", i, err)
		}
	}
	if _, err := h.svc.AdminVerifyTOTP(ctx, ch.ID, "000000"); !errors.Is(err, domain.ErrChallengeExpired) {
		t.Fatal("challenge survived too many codes")
	}
	steps := map[string]func(){
		"admin":  func() { h.repo.faults["AdminByID"] = errBoom },
		"delete": func() { h.challenges.faults["Delete"] = errBoom },
		"save":   func() { h.repo.faults["SaveAdmin"] = errBoom },
		"decrypt": func() {
			h.box.faults["Decrypt"] = errBoom
			enrolled := h.repo.admins[a.ID]
			enrolled.TOTPEnrolled = true
			enrolled.TOTPSecretEnc = []byte("enc:JBSWY3DPEHPK3PXP")
			h.repo.admins[a.ID] = enrolled
		},
	}
	for name, set := range steps {
		t.Run(name, func(t *testing.T) {
			h.repo.faults, h.challenges.faults, h.box.faults = faults{}, faults{}, faults{}
			if name == "decrypt" {
				set()
			}
			ch, err := h.svc.AdminLogin(ctx, "verifier@pao.bd", pw)
			if err != nil {
				t.Fatal(err)
			}
			if name != "decrypt" {
				set()
			}
			secret := ch.EnrolSecret
			if secret == "" {
				secret = "JBSWY3DPEHPK3PXP"
			}
			if _, err := h.svc.AdminVerifyTOTP(ctx, ch.ID, h.totp(t, secret)); !errors.Is(err, errBoom) {
				t.Fatalf("err = %v", err)
			}
		})
	}
}

func TestChangeAdminPassword_Refusals(t *testing.T) {
	h := newHarness()
	a, pw := h.newAdmin(t)
	if err := h.svc.ChangeAdminPassword(ctx, a.ID, "wrong", "a much longer passphrase 1"); !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatal("wrong current password")
	}
	if err := h.svc.ChangeAdminPassword(ctx, a.ID, pw, "short"); !errors.Is(err, domain.ErrPasswordTooWeak) {
		t.Fatal("weak password")
	}
	h.repo.faults["AdminByID"] = errBoom
	if err := h.svc.ChangeAdminPassword(ctx, a.ID, pw, "x"); !errors.Is(err, errBoom) {
		t.Fatal("lookup failure")
	}
	h.repo.faults = faults{}
	broken := h.repo.admins[a.ID]
	broken.PasswordHash = "x"
	h.repo.admins[a.ID] = broken
	if err := h.svc.ChangeAdminPassword(ctx, a.ID, pw, "x"); !errors.Is(err, auth.ErrHashMalformed) {
		t.Fatal("malformed hash")
	}
}

func TestCreateAndUpdateAdmin(t *testing.T) {
	h := newHarness()
	a, _ := h.newAdmin(t)
	if _, _, err := h.svc.CreateAdmin(ctx, CreateAdminInput{Email: "verifier@pao.bd", Roles: []string{"verifier"}}); !errors.Is(err, domain.ErrEmailTaken) {
		t.Fatal("duplicate email")
	}
	if _, _, err := h.svc.CreateAdmin(ctx, CreateAdminInput{Email: "x@pao.bd", Roles: []string{"customer"}}); !errors.Is(err, domain.ErrRoleInvalid) {
		t.Fatal("customer role accepted for admin")
	}
	inactive := false
	got, err := h.svc.UpdateAdmin(ctx, UpdateAdminInput{AdminID: a.ID, Roles: []string{"support_agent"}, Active: &inactive})
	if err != nil || got.Active || got.Roles[0] != "support_agent" {
		t.Fatalf("update: %+v %v", got, err)
	}
	if _, err := h.svc.UpdateAdmin(ctx, UpdateAdminInput{AdminID: a.ID, Roles: []string{"customer"}}); !errors.Is(err, domain.ErrRoleInvalid) {
		t.Fatal("bad role")
	}
	list, err := h.svc.ListAdmins(ctx)
	if err != nil || len(list) != 1 {
		t.Fatalf("list: %v", err)
	}
}

func TestCreateAndUpdateAdmin_Failures(t *testing.T) {
	for _, step := range []string{"AdminByEmail", "CreateAccount", "SetRoles", "CreateAdminCredentials"} {
		h := newHarness()
		h.repo.faults[step] = errBoom
		if _, _, err := h.svc.CreateAdmin(ctx, CreateAdminInput{Email: "a@pao.bd", Roles: []string{"verifier"}}); !errors.Is(err, errBoom) {
			t.Errorf("create %s: %v", step, err)
		}
	}
	for _, step := range []string{"AdminByID", "SetRoles", "ListForAccount"} {
		h := newHarness()
		a, _ := h.newAdmin(t)
		h.repo.faults[step] = errBoom
		h.sessions.faults[step] = errBoom
		if _, err := h.svc.UpdateAdmin(ctx, UpdateAdminInput{AdminID: a.ID, Roles: []string{"verifier"}}); !errors.Is(err, errBoom) {
			t.Errorf("update %s: %v", step, err)
		}
	}
}
