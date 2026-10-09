package domain

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestNormalizePhone(t *testing.T) {
	valid := map[string]Phone{
		"01712345678":       "+8801712345678",
		"8801712345678":     "+8801712345678",
		"+8801712345678":    "+8801712345678",
		" +880 1712-345678": "+8801712345678",
		"(017) 1234 5678":   "+8801712345678",
		"1912345678":        "+8801912345678",
	}
	for in, want := range valid {
		if got, err := NormalizePhone(in); err != nil || got != want {
			t.Errorf("NormalizePhone(%q) = %q, %v", in, got, err)
		}
	}
	for _, bad := range []string{"", "0171234567", "01212345678", "+9101712345678", "017123456789", "phone"} {
		if _, err := NormalizePhone(bad); !errors.Is(err, ErrInvalidPhone) {
			t.Errorf("NormalizePhone(%q) accepted", bad)
		}
	}
	if Phone("+8801712345678").Masked() != "***********678" || Phone("1").Masked() != "***" {
		t.Fatal("masking wrong")
	}
}

func TestAccount_SignInAndStatus(t *testing.T) {
	now := time.Now()
	cases := []struct {
		acc  Account
		want error
	}{
		{Account{Status: StatusActive}, nil},
		{Account{Status: StatusPending}, nil},
		{Account{Status: StatusSuspended}, ErrAccountSuspended},
		{Account{Status: StatusBanned}, ErrAccountBanned},
		{Account{Status: StatusActive, DeletedAt: &now}, ErrAccountDeleted},
	}
	for _, c := range cases {
		if err := c.acc.CanSignIn(); !errors.Is(err, c.want) {
			t.Errorf("%+v: %v", c.acc, err)
		}
	}
	active := Account{Status: StatusActive, Roles: []string{RoleCustomer}}
	for _, to := range []Status{StatusSuspended, StatusBanned} {
		if err := active.ChangeStatus(to); err != nil {
			t.Errorf("active → %s: %v", to, err)
		}
	}
	if (Account{Status: StatusBanned}).ChangeStatus(StatusActive) != nil {
		t.Error("reinstating a banned account refused")
	}
	for _, bad := range []struct {
		a  Account
		to Status
	}{{active, StatusActive}, {active, StatusPending}, {Account{Status: StatusActive, DeletedAt: &now}, StatusBanned}} {
		if !errors.Is(bad.a.ChangeStatus(bad.to), ErrStatusChange) {
			t.Errorf("%s → %s allowed", bad.a.Status, bad.to)
		}
	}
	if !active.HasRole(RoleCustomer) || active.HasRole(RoleProvider) {
		t.Fatal("HasRole wrong")
	}
	if RoleForApp("partner") != RoleProvider || RoleForApp("customer") != RoleCustomer {
		t.Fatal("RoleForApp wrong")
	}
	if !IsAdminRoleSet([]string{RoleVerifier, RoleSuperAdmin}) || IsAdminRoleSet(nil) || IsAdminRoleSet([]string{RoleCustomer}) {
		t.Fatal("IsAdminRoleSet wrong")
	}
}

func TestStoredCode_AttemptsAndLockout(t *testing.T) {
	if discard, err := (StoredCode{Attempts: 0}).CheckAttempt(true); err != nil || !discard {
		t.Fatal("match not accepted")
	}
	if discard, err := (StoredCode{Attempts: 3}).CheckAttempt(false); !errors.Is(err, ErrCodeInvalid) || discard {
		t.Fatal("4th wrong guess")
	}
	if discard, err := (StoredCode{Attempts: 4}).CheckAttempt(false); !errors.Is(err, ErrCodeLocked) || !discard {
		t.Fatal("5th wrong guess not locked")
	}
}

func TestRefreshToken(t *testing.T) {
	id := uuid.New()
	tok := FormatRefreshToken(id, "secret")
	gotID, secret, err := ParseRefreshToken(tok)
	if err != nil || gotID != id || secret != "secret" {
		t.Fatalf("parse: %v %v %v", gotID, secret, err)
	}
	for _, bad := range []string{"", "nodot", "not-a-uuid.secret", id.String() + "."} {
		if _, _, err := ParseRefreshToken(bad); !errors.Is(err, ErrRefreshInvalid) {
			t.Errorf("%q parsed", bad)
		}
	}
	f := Family{CurrentHash: "abc"}
	if !f.Matches("abc") || f.Matches("abd") {
		t.Fatal("Matches wrong")
	}
	if len(ProviderGateScreens) != 14 {
		t.Fatal("gate screens")
	}
}

func TestAdmin_LockoutAndLogin(t *testing.T) {
	now := time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)
	a := Admin{Active: true}
	for i := 0; i < AdminMaxFailures-1; i++ {
		a.RecordFailure(now)
	}
	if a.CheckCanLogin(now) != nil {
		t.Fatal("locked too early")
	}
	a.RecordFailure(now)
	if !errors.Is(a.CheckCanLogin(now), ErrAdminLocked) || a.FailedAttempts != 0 {
		t.Fatal("not locked after the limit")
	}
	if a.CheckCanLogin(now.Add(AdminLockout)) != nil {
		t.Fatal("lock did not expire")
	}
	a.RecordSuccess()
	if a.LockedUntil != nil {
		t.Fatal("success kept the lock")
	}
	if !errors.Is((Admin{}).CheckCanLogin(now), ErrAdminInactive) {
		t.Fatal("inactive admin may log in")
	}
}

func TestValidatePassword(t *testing.T) {
	for pw, ok := range map[string]bool{
		"short1":                     false,
		"onlyletterslongenough":      false,
		"123456789012345":            false,
		"correct horse battery 2026": true,
	} {
		if err := ValidatePassword(pw); (err == nil) != ok {
			t.Errorf("%q: %v", pw, err)
		}
	}
}
