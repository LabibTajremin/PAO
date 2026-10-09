//go:build integration

package http_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestContract_InProcessAdapter(t *testing.T) {
	a := testkit.NewAPI(t)
	c := a.Modules.Identity.Contract
	ctx := context.Background()
	tp := a.SignIn(t, phone, "customer")
	acc, err := c.GetAccount(ctx, tp.Account.Id)
	if err != nil || acc.Phone != "+8801712345678" || acc.Roles[0] != contract.RoleCustomer {
		t.Fatalf("get: %+v %v", acc, err)
	}
	if ok, err := c.HasRole(ctx, tp.Account.Id, contract.RoleProvider); ok || err != nil {
		t.Fatal("has role")
	}
	if _, err := c.GetAccount(ctx, uuid.New()); !errors.Is(err, contract.ErrAccountNotFound) {
		t.Fatalf("missing account: %v", err)
	}
	if _, err := c.HasRole(ctx, uuid.New(), contract.RoleProvider); !errors.Is(err, contract.ErrAccountNotFound) {
		t.Fatal("missing account role")
	}
	if _, err := c.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: tp.Account.Id, Status: contract.StatusActive}); !errors.Is(err, contract.ErrStatusInvalid) {
		t.Fatalf("no-op status: %v", err)
	}
	if _, err := c.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: tp.Account.Id, Status: contract.StatusBanned}); err != nil {
		t.Fatal(err)
	}
	if _, err := c.SetAccountStatus(ctx, contract.SetAccountStatusInput{AccountID: tp.Account.Id, Status: contract.StatusActive, Reason: "appeal"}); err != nil {
		t.Fatalf("reinstate: %v", err)
	}
	if err := c.SendPhoneCode(ctx, "01912345678", contract.PurposeEmergencyContact); err != nil {
		t.Fatal(err)
	}
	if err := c.CheckPhoneCode(ctx, "01912345678", contract.PurposeEmergencyContact, "x"); !errors.Is(err, contract.ErrCodeInvalid) {
		t.Fatalf("wrong code: %v", err)
	}
	if err := c.CheckPhoneCode(ctx, "01912345678", contract.PurposeEmergencyContact, a.LastCode(t, "01912345678")); err != nil {
		t.Fatalf("right code: %v", err)
	}
}

func TestEndpoints_EdgeCases(t *testing.T) {
	a := testkit.NewAPI(t)
	customer := a.SignIn(t, phone, "customer")
	auth := testkit.Bearer(customer.AccessToken)
	if r := a.Do(t, "POST", "/v1/auth/admin/password", map[string]string{"currentPassword": "whatever1", "newPassword": "a much longer passphrase 1"}, auth); r.Status != 404 {
		t.Fatalf("customer changing admin password: %d %s", r.Status, r.Body)
	}
	if _, err := a.Infra.Pool.Exec(context.Background(), "DELETE FROM identity.account_roles WHERE account_id = $1", customer.Account.Id); err != nil {
		t.Fatal(err)
	}
	r := a.Do(t, "GET", "/v1/me/permissions", nil, auth)
	if r.Status != 200 || len(r.JSON(t)["permissions"].([]any)) != 0 {
		t.Fatalf("role-less permissions: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "DELETE", "/v1/me", map[string]string{"code": "123456"}, auth); r.Code(t) != "OTP_EXPIRED" {
		t.Fatalf("delete without a code: %s", r.Body)
	}
}

func TestEndpoints_ReportStoreFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	super := a.Admin(t, "super_admin")
	customer := a.SignIn(t, phone, "customer")
	// Warm the RBAC cache so authorisation passes and the handlers meet the failure.
	a.Do(t, "GET", "/v1/admin/roles", nil, testkit.Bearer(super.AccessToken))
	a.Do(t, "GET", "/v1/me", nil, testkit.Bearer(customer.AccessToken))
	a.Infra.Pool.Close()
	calls := []struct {
		method, path, token string
		body                any
	}{
		{"GET", "/v1/me", customer.AccessToken, nil},
		{"GET", "/v1/me/permissions", customer.AccessToken, nil},
		{"DELETE", "/v1/me", customer.AccessToken, map[string]string{"code": "123456"}},
		{"GET", "/v1/admin/admin-users", super.AccessToken, nil},
		{"POST", "/v1/admin/admin-users", super.AccessToken, map[string]any{"email": "x@pao.bd", "name": "Xavier", "roles": []string{"verifier"}}},
		{"PATCH", "/v1/admin/admin-users/" + super.ID.String(), super.AccessToken, map[string]any{"active": true}},
		{"GET", "/v1/admin/roles", super.AccessToken, nil},
		{"PUT", "/v1/admin/roles/verifier", super.AccessToken, map[string]any{"permissions": []string{}, "screens": []string{}}},
		{"POST", "/v1/auth/admin/login", "", map[string]string{"email": super.Email, "password": "whatever12"}},
		{"POST", "/v1/auth/admin/password", super.AccessToken, map[string]string{"currentPassword": "whatever12", "newPassword": "a much longer passphrase 1"}},
	}
	for _, c := range calls {
		var opts []testkit.Request
		if c.token != "" {
			opts = append(opts, testkit.Bearer(c.token))
		}
		if r := a.Do(t, c.method, c.path, c.body, opts...); r.Status != 500 {
			t.Errorf("%s %s = %d %s", c.method, c.path, r.Status, r.Body)
		}
	}
}

func TestEndpoints_ReportRedisFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	customer := a.SignIn(t, phone, "customer")
	_ = a.Infra.Redis.Close()
	for _, c := range []struct{ method, path string }{{"POST", "/v1/auth/logout"}, {"GET", "/v1/me"}} {
		if r := a.Do(t, c.method, c.path, map[string]bool{}, testkit.Bearer(customer.AccessToken)); r.Status != 500 {
			t.Errorf("%s %s = %d", c.method, c.path, r.Status)
		}
	}
	for _, path := range []string{"/v1/auth/otp/request", "/v1/auth/otp/verify", "/v1/auth/refresh", "/v1/auth/admin/totp"} {
		body := map[string]string{"phone": phone, "code": "123456", "app": "customer", "refreshToken": uuid.NewString() + ".x", "challengeId": uuid.NewString()}
		if r := a.Do(t, "POST", path, body); r.Status != 500 {
			t.Errorf("POST %s = %d %s", path, r.Status, r.Body)
		}
	}
}

func TestLogout_ReportsSessionStoreFailure(t *testing.T) {
	a := testkit.NewAPI(t)
	tp := a.SignIn(t, phone, "customer")
	sid := uuid.New()
	a.Infra.Redis.Set(context.Background(), a.Infra.Keys.Key("rt", sid.String()), "not-a-hash", 0)
	token := a.TokenWithSession(t, tp.Account.Id, sid, "customer")
	if r := a.Do(t, "POST", "/v1/auth/logout", map[string]bool{}, testkit.Bearer(token)); r.Status != 500 {
		t.Fatalf("logout = %d %s", r.Status, r.Body)
	}
}
