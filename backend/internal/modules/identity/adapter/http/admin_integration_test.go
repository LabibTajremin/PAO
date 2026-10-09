//go:build integration

package http_test

import (
	"net/http"
	"os"
	"regexp"
	"strings"
	"testing"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"

	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestAdminLogin_CookieRefreshAndPassword(t *testing.T) {
	a := testkit.NewAPI(t)
	s := a.Admin(t, "super_admin")
	if !strings.HasPrefix(s.RefreshCookie, "pao_refresh=") {
		t.Fatalf("cookie = %q", s.RefreshCookie)
	}
	r := a.Do(t, "POST", "/v1/auth/refresh", nil, testkit.Header("Cookie", s.RefreshCookie))
	var tp api.TokenPair
	r.Decode(t, &tp)
	if r.Status != 200 || tp.RefreshToken != nil || !strings.Contains(r.Header.Get("Set-Cookie"), "HttpOnly") {
		t.Fatalf("cookie refresh: %d %s", r.Status, r.Body)
	}
	pw := map[string]string{"currentPassword": s.Password, "newPassword": "a much longer passphrase 1"}
	if r := a.Do(t, "POST", "/v1/auth/admin/password", pw, testkit.Bearer(tp.AccessToken)); r.Status != 204 {
		t.Fatalf("change password: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/auth/admin/password", pw, testkit.Bearer(tp.AccessToken)); r.Code(t) != "INVALID_CREDENTIALS" {
		t.Fatalf("old password accepted: %s", r.Body)
	}
	r = a.Do(t, "POST", "/v1/auth/admin/login", map[string]string{"email": s.Email, "password": "a much longer passphrase 1"})
	var ch api.AdminLoginChallenge
	r.Decode(t, &ch)
	if r.Status != 200 || ch.TotpEnrolment != nil || *ch.MustChangePassword {
		t.Fatalf("second login: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/auth/admin/totp", map[string]string{"challengeId": ch.ChallengeId.String(), "code": "000000"}); r.Code(t) != "TOTP_INVALID" {
		t.Fatalf("wrong totp: %s", r.Body)
	}
	code, _ := auth.TOTPCode(s.TOTPSecret, a.Clock.Now())
	if r := a.Do(t, "POST", "/v1/auth/admin/totp", map[string]string{"challengeId": ch.ChallengeId.String(), "code": code}); r.Status != 200 {
		t.Fatalf("totp: %d %s", r.Status, r.Body)
	}
	r = a.Do(t, "POST", "/v1/auth/logout", map[string]bool{}, testkit.Bearer(tp.AccessToken), testkit.Header("Cookie", s.RefreshCookie))
	if r.Status != 204 || !strings.Contains(r.Header.Get("Set-Cookie"), "Max-Age=0") {
		t.Fatalf("logout: %d %v", r.Status, r.Header)
	}
}

func TestAdminLogin_LockoutAndUnknownChallenge(t *testing.T) {
	a := testkit.NewAPI(t)
	s := a.Admin(t, "verifier")
	for i := 0; i < 5; i++ {
		a.Do(t, "POST", "/v1/auth/admin/login", map[string]string{"email": s.Email, "password": "wrong-password"})
	}
	if r := a.Do(t, "POST", "/v1/auth/admin/login", map[string]string{"email": s.Email, "password": s.Password}); r.Status != 429 || r.Code(t) != "ACCOUNT_LOCKED" {
		t.Fatalf("lockout: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/auth/admin/totp", map[string]string{"challengeId": uuid.NewString(), "code": "123456"}); r.Code(t) != "MFA_CHALLENGE_EXPIRED" {
		t.Fatalf("unknown challenge: %s", r.Body)
	}
}

func TestAdminUsersAndRoles(t *testing.T) {
	a := testkit.NewAPI(t)
	super := a.Admin(t, "super_admin")
	auth := testkit.Bearer(super.AccessToken)
	r := a.Do(t, "POST", "/v1/admin/admin-users", map[string]any{"email": "support@pao.bd", "name": "Support", "roles": []string{"support_agent"}}, auth)
	var invited api.AdminUserInvited
	r.Decode(t, &invited)
	if r.Status != 201 || invited.TemporaryPassword == "" {
		t.Fatalf("invite: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/admin/admin-users", map[string]any{"email": "support@pao.bd", "name": "Support", "roles": []string{"support_agent"}}, auth); r.Status != 409 {
		t.Fatalf("duplicate invite: %d", r.Status)
	}
	r = a.Do(t, "PATCH", "/v1/admin/admin-users/"+invited.User.Id.String(), map[string]any{"active": false, "roles": []string{"verifier"}}, auth)
	if r.Status != 200 || r.JSON(t)["active"] != false {
		t.Fatalf("patch: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "GET", "/v1/admin/admin-users", nil, auth); r.Status != 200 || len(r.JSON(t)["items"].([]any)) != 2 {
		t.Fatalf("list: %d %s", r.Status, r.Body)
	}
	r = a.Do(t, "GET", "/v1/admin/roles", nil, auth)
	if r.Status != 200 || len(r.JSON(t)["items"].([]any)) != 6 {
		t.Fatalf("roles: %d %s", r.Status, r.Body)
	}
	upd := map[string]any{"permissions": []string{"verification:review", "dashboard:read"}, "screens": []string{"A01", "A05"}}
	if r := a.Do(t, "PUT", "/v1/admin/roles/verifier", upd, auth); r.Status != 200 {
		t.Fatalf("update role: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/admin/roles/verifier", map[string]any{"permissions": []string{"made:up"}, "screens": []string{}}, auth); r.Code(t) != "ROLE_INVALID" {
		t.Fatalf("bad role update: %s", r.Body)
	}
	customer := a.SignIn(t, "01812345678", "customer")
	if r := a.Do(t, "GET", "/v1/admin/roles", nil, testkit.Bearer(customer.AccessToken)); r.Status != http.StatusForbidden {
		t.Fatalf("customer read roles: %d", r.Status)
	}
}

// TestEveryProtectedRoute_RefusesATokenWithoutItsPermission walks the whole spec.
func TestEveryProtectedRoute_RefusesATokenWithoutItsPermission(t *testing.T) {
	a := testkit.NewAPI(t)
	token := a.Token(t, uuid.New())
	raw, err := os.ReadFile("../../../../platform/httpx/api/openapi.gen.yaml")
	if err != nil {
		t.Fatal(err)
	}
	var spec struct {
		Paths map[string]map[string]struct {
			Permission string `yaml:"x-permission"`
		} `yaml:"paths"`
	}
	if err := yaml.Unmarshal(raw, &spec); err != nil {
		t.Fatal(err)
	}
	fill := strings.NewReplacer("{role}", "customer", "{itemType}", "nid", "{key}", "booking.accept_timeout_asap_seconds")
	param := regexp.MustCompile(`\{[a-zA-Z]+\}`)
	checked := 0
	for path, ops := range spec.Paths {
		for method, op := range ops {
			if op.Permission == "public" || op.Permission == "authenticated" {
				continue
			}
			url := param.ReplaceAllString(fill.Replace(path), uuid.NewString())
			r := a.Do(t, strings.ToUpper(method), url, nil, testkit.Bearer(token))
			if r.Status != http.StatusForbidden {
				t.Errorf("%s %s (%s) = %d", strings.ToUpper(method), path, op.Permission, r.Status)
			}
			checked++
		}
	}
	if checked < 100 {
		t.Fatalf("only %d operations checked", checked)
	}
}
