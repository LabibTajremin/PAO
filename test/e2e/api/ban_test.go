package api

import (
	"net/http"
	"testing"
	"time"
)

func TestBan_ProviderLosesSessionsSearchAndSignIn(t *testing.T) {
	c := customer(t, phoneFor(t, "017", 41))
	svc, sub := service(t, c, "Electrician")
	p := onlineProvider(t, 42, svc)
	eventually(t, 10*time.Second, "provider in nearby search", func() bool { return nearby(t, c, svc, sub, p.ID) })

	banned := must(t, 200, "POST", "/v1/admin/providers/"+p.ID+"/status",
		map[string]string{"status": "banned", "reason": "Fraudulent documents"}, admin(t, "super@pao.bd"))
	if banned["summary"].(map[string]any)["status"] != "banned" {
		t.Fatalf("ban: %v", banned)
	}
	expectLockedOut(t, p.session, p.Phone, "/v1/provider/profile")
	eventually(t, 10*time.Second, "banned provider hidden from search", func() bool { return !nearby(t, c, svc, sub, p.ID) })
}

func TestBan_CustomerLosesSessionsAndSignIn(t *testing.T) {
	phone := phoneFor(t, "017", 43)
	c := customer(t, phone)
	must(t, 200, "GET", "/v1/customer/profile", nil, c)
	if r := do(t, "POST", "/v1/admin/customers/"+c.ID+"/status", map[string]string{"status": "banned"}, admin(t, "super@pao.bd")); r.Status != 422 {
		t.Fatalf("ban without a reason: %d %s", r.Status, r.Body)
	}
	must(t, 200, "POST", "/v1/admin/customers/"+c.ID+"/status",
		map[string]string{"status": "banned", "reason": "Abused providers"}, admin(t, "super@pao.bd"))
	expectLockedOut(t, c, phone, "/v1/customer/profile")
}

// expectLockedOut waits for the ban to reach identity (the worker relays it), then
// checks the old access token is refused and the phone cannot ask for a login code.
func expectLockedOut(t *testing.T, s session, phone, path string) {
	t.Helper()
	eventually(t, 10*time.Second, "session revoked", func() bool { return do(t, "GET", path, nil, s).Status == http.StatusUnauthorized })
	eventually(t, 10*time.Second, "sign-in refused", func() bool {
		r := requestCode(t, phone)
		if r.Status == http.StatusAccepted {
			t.Fatalf("a banned phone was sent a login code")
		}
		return r.Status == http.StatusForbidden && r.Code(t) == "ACCOUNT_BANNED"
	})
}
