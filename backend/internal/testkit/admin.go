package testkit

import (
	"context"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// AdminSession is a signed-in admin.
type AdminSession struct {
	ID            uuid.UUID
	Email         string
	Password      string
	TOTPSecret    string
	AccessToken   string
	RefreshCookie string
}

// Admin creates an admin with roles and signs them in through password + TOTP.
func (a *API) Admin(t testing.TB, roles ...string) AdminSession {
	t.Helper()
	email := strings.ReplaceAll(uuid.NewString(), "-", "")[:12] + "@pao.bd"
	admin, temp, err := a.Modules.Identity.Service.CreateAdmin(context.Background(), app.CreateAdminInput{Email: email, Name: "Test Admin", Roles: roles})
	if err != nil {
		t.Fatalf("create admin: %v", err)
	}
	s := AdminSession{ID: admin.ID, Email: email, Password: temp}
	r := a.Do(t, "POST", "/v1/auth/admin/login", map[string]string{"email": email, "password": temp})
	if r.Status != http.StatusOK {
		t.Fatalf("admin login: %d %s", r.Status, r.Body)
	}
	var ch api.AdminLoginChallenge
	r.Decode(t, &ch)
	s.TOTPSecret = ch.TotpEnrolment.Secret
	code, _ := auth.TOTPCode(s.TOTPSecret, a.Infra.Clock.Now())
	r = a.Do(t, "POST", "/v1/auth/admin/totp", map[string]string{"challengeId": ch.ChallengeId.String(), "code": code})
	if r.Status != http.StatusOK {
		t.Fatalf("admin totp: %d %s", r.Status, r.Body)
	}
	var tp api.TokenPair
	r.Decode(t, &tp)
	s.AccessToken = tp.AccessToken
	s.RefreshCookie = strings.Split(r.Header.Get("Set-Cookie"), ";")[0]
	return s
}
