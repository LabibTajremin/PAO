//go:build integration

package http_test

import (
	"context"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

const phone = "01712345678"

func TestOTPSignIn_RefreshAndLogout(t *testing.T) {
	a := testkit.NewAPI(t)
	tp := a.SignIn(t, phone, "customer")
	if tp.RefreshToken == nil || !*tp.IsNewAccount || tp.Account.Roles[0] != api.RoleCustomer {
		t.Fatalf("token pair: %+v", tp)
	}
	me := a.Do(t, "GET", "/v1/me", nil, testkit.Bearer(tp.AccessToken))
	if me.Status != 200 || me.JSON(t)["phone"] != "+8801712345678" {
		t.Fatalf("me: %d %s", me.Status, me.Body)
	}
	r := a.Do(t, "POST", "/v1/auth/refresh", map[string]string{"refreshToken": *tp.RefreshToken})
	var next api.TokenPair
	r.Decode(t, &next)
	if r.Status != 200 || *next.RefreshToken == *tp.RefreshToken {
		t.Fatalf("refresh: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/auth/refresh", map[string]string{"refreshToken": *tp.RefreshToken}); r.Status != 401 || r.Code(t) != "REFRESH_TOKEN_INVALID" {
		t.Fatalf("reuse: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/auth/refresh", map[string]string{"refreshToken": *next.RefreshToken}); r.Status != 401 {
		t.Fatal("family survived reuse")
	}
	fresh := a.SignInAgain(t, phone, "customer")
	if r := a.Do(t, "POST", "/v1/auth/logout", map[string]bool{"allDevices": false}, testkit.Bearer(fresh.AccessToken)); r.Status != 204 {
		t.Fatalf("logout: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "GET", "/v1/me", nil, testkit.Bearer(fresh.AccessToken)); r.Status != 401 {
		t.Fatalf("token after logout: %d", r.Status)
	}
}

func TestOTP_ErrorsAndLimits(t *testing.T) {
	a := testkit.NewAPI(t)
	if r := a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": "123"}); r.Status != 422 {
		t.Fatalf("bad phone: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone}); r.Status != 202 {
		t.Fatalf("first request: %d %s", r.Status, r.Body)
	}
	r := a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone})
	if r.Status != 429 || r.Header.Get("Retry-After") == "" || r.Code(t) != "RATE_LIMITED" {
		t.Fatalf("resend too soon: %d %v", r.Status, r.Header)
	}
	code := a.LastCode(t, phone)
	wrong := "000000"
	if code == wrong {
		wrong = "111111"
	}
	if r := a.Do(t, "POST", "/v1/auth/otp/verify", map[string]string{"phone": phone, "code": wrong, "app": "customer"}); r.Status != 401 || r.Code(t) != "OTP_INVALID" {
		t.Fatalf("wrong code: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/auth/otp/verify", map[string]string{"phone": "01812345678", "code": "123456", "app": "customer"}); r.Code(t) != "OTP_EXPIRED" {
		t.Fatalf("no code: %s", r.Body)
	}
	for i := 0; i < 4; i++ {
		a.Do(t, "POST", "/v1/auth/otp/verify", map[string]string{"phone": phone, "code": wrong, "app": "customer"})
	}
	if r := a.Do(t, "POST", "/v1/auth/otp/verify", map[string]string{"phone": phone, "code": code, "app": "customer"}); r.Code(t) != "OTP_EXPIRED" {
		t.Fatalf("locked code still valid: %s", r.Body)
	}
}

func TestPartnerSignIn_ProviderGate(t *testing.T) {
	a := testkit.NewAPI(t)
	tp := a.SignIn(t, phone, "partner")
	r := a.Do(t, "GET", "/v1/me/permissions", nil, testkit.Bearer(tp.AccessToken))
	var perms api.MyPermissions
	r.Decode(t, &perms)
	if r.Status != 200 || !*perms.ProviderGate || len(perms.Screens) != 14 || perms.Roles[0] != api.RoleProvider {
		t.Fatalf("permissions: %d %s", r.Status, r.Body)
	}
}

func TestBannedAccount_CannotSignIn(t *testing.T) {
	a := testkit.NewAPI(t)
	tp := a.SignIn(t, phone, "customer")
	_, err := a.Modules.Identity.Contract.SetAccountStatus(context.Background(), contract.SetAccountStatusInput{
		AccountID: tp.Account.Id, Status: contract.StatusBanned, Reason: "fraud",
	})
	if err != nil {
		t.Fatal(err)
	}
	if r := a.Do(t, "GET", "/v1/me", nil, testkit.Bearer(tp.AccessToken)); r.Status != 401 {
		t.Fatalf("banned token still works: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/auth/refresh", map[string]string{"refreshToken": *tp.RefreshToken}); r.Status != 401 {
		t.Fatalf("banned refresh: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone}); r.Status != 403 || r.Code(t) != "ACCOUNT_BANNED" {
		t.Fatalf("banned phone got a code: %d %s", r.Status, r.Body)
	}
}

func TestDeleteMe(t *testing.T) {
	a := testkit.NewAPI(t)
	tp := a.SignIn(t, phone, "customer")
	a.Clock.Advance(time.Minute)
	if r := a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone, "purpose": "delete_account"}); r.Status != 202 {
		t.Fatalf("delete code: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "DELETE", "/v1/me", map[string]string{"code": a.LastCode(t, phone)}, testkit.Bearer(tp.AccessToken)); r.Status != 204 {
		t.Fatalf("delete: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "GET", "/v1/me", nil, testkit.Bearer(tp.AccessToken)); r.Status != 401 {
		t.Fatalf("deleted account token: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/auth/refresh", map[string]string{"refreshToken": *tp.RefreshToken}); r.Status != 401 {
		t.Fatal("deleted account refreshed")
	}
}
