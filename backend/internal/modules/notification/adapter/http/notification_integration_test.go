//go:build integration

package http_test

import (
	"context"
	"fmt"
	"slices"
	"strings"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func inbox(t *testing.T, a *testkit.API, path string, who testkit.Request) map[string]any {
	t.Helper()
	r := a.Do(t, "GET", path, nil, who)
	if r.Status != 200 {
		t.Fatalf("%s: %d %s", path, r.Status, r.Body)
	}
	return r.JSON(t)
}

func types(page map[string]any) []string {
	var out []string
	for _, it := range page["items"].([]any) {
		out = append(out, it.(map[string]any)["type"].(string))
	}
	return out
}

func TestNotifications_BookingEventsReachBothSides(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	j := a.RequestedJob(t, "01712345631", "01812345631")
	device := map[string]string{"token": "provider-device-token-1", "platform": "android"}
	if r := a.Do(t, "PUT", "/v1/provider/device-token", device, j.Provider.Auth()); r.Status != 204 {
		t.Fatalf("device: %d %s", r.Status, r.Body)
	}
	a.Do(t, "PUT", "/v1/provider/device-token", map[string]string{"token": "invalid-provider-device", "platform": "ios"}, j.Provider.Auth())
	a.Do(t, "PUT", "/v1/customer/device-token", map[string]string{"token": "customer-device-token-1", "platform": "android"}, j.Customer.Auth())
	a.RelayEvents(t)
	pushes := a.Modules.PushCapture.To("provider-device-token-1")
	if len(pushes) != 1 || pushes[0].Push.Data["type"] != "booking_requested" || pushes[0].Push.Data["bookingId"] != j.ID {
		t.Fatalf("provider push: %+v", pushes)
	}
	var tokens int
	_ = a.Infra.Pool.QueryRow(ctx, "SELECT count(*) FROM notification.device_tokens WHERE token LIKE 'invalid-%'").Scan(&tokens)
	if tokens != 0 {
		t.Fatal("dead token kept")
	}
	path := "/v1/provider/jobs/" + j.ID
	a.Do(t, "POST", path+"/accept", nil, j.Provider.Auth())
	a.Do(t, "POST", path+"/on-the-way", nil, j.Provider.Auth())
	a.Do(t, "POST", path+"/cancel", map[string]string{"reason": "emergency"}, j.Provider.Auth())
	a.RelayEvents(t)
	if _, err := a.Infra.Pool.Exec(ctx, "UPDATE booking.outbox SET published_at = NULL"); err != nil {
		t.Fatal(err)
	}
	a.RelayEvents(t)
	cust := inbox(t, a, "/v1/customer/notifications", j.Customer.Auth())
	got := types(cust)
	if len(got) != 3 || got[0] != "booking_cancelled" || got[2] != "booking_accepted" || cust["unreadCount"] != float64(3) {
		t.Fatalf("customer inbox: %v", cust)
	}
	if first := cust["items"].([]any)[2].(map[string]any); first["title"] != "Booking accepted" {
		t.Fatalf("English title for an English customer: %v", first)
	}
	if n := len(a.Modules.PushCapture.To("customer-device-token-1")); n != 3 {
		t.Fatalf("customer pushes after redelivery: %d", n)
	}
	page := inbox(t, a, "/v1/customer/notifications?limit=2", j.Customer.Auth())
	next := inbox(t, a, "/v1/customer/notifications?limit=2&cursor="+page["nextCursor"].(string), j.Customer.Auth())
	if len(next["items"].([]any)) != 1 {
		t.Fatalf("page 2: %v", next)
	}
	id := cust["items"].([]any)[0].(map[string]any)["id"].(string)
	if r := a.Do(t, "POST", "/v1/provider/notifications/"+id+"/read", nil, j.Provider.Auth()); r.Status != 404 {
		t.Fatalf("other's notification: %d", r.Status)
	}
	a.Do(t, "POST", "/v1/customer/notifications/"+id+"/read", nil, j.Customer.Auth())
	if r := inbox(t, a, "/v1/customer/notifications", j.Customer.Auth()); r["unreadCount"] != float64(2) {
		t.Fatalf("after read: %v", r["unreadCount"])
	}
	for _, p := range []struct {
		path string
		who  testkit.Request
	}{{"/v1/customer/notifications/read-all", j.Customer.Auth()}, {"/v1/provider/notifications/read-all", j.Provider.Auth()}} {
		if r := a.Do(t, "POST", p.path, nil, p.who); r.Status != 204 {
			t.Fatalf("%s: %d", p.path, r.Status)
		}
	}
	prov := inbox(t, a, "/v1/provider/notifications", j.Provider.Auth())
	if prov["unreadCount"] != float64(0) || !slices.Contains(types(prov), "booking_requested") {
		t.Fatalf("provider inbox: %v", prov)
	}
	pid := prov["items"].([]any)[0].(map[string]any)["id"].(string)
	if r := a.Do(t, "POST", "/v1/provider/notifications/"+pid+"/read", nil, j.Provider.Auth()); r.Status != 204 {
		t.Fatalf("provider read: %d", r.Status)
	}
	a.Deliver(t, identity.AccountDeleted{AccountID: j.Customer.ID})
	if r := inbox(t, a, "/v1/customer/notifications", j.Customer.Auth()); len(r["items"].([]any)) != 0 {
		t.Fatal("deleted account kept its inbox")
	}
}

func TestNotifications_VerificationEvents(t *testing.T) {
	a := testkit.NewAPI(t)
	p := a.SignIn(t, "01712345641", "partner")
	auth := testkit.Bearer(p.AccessToken)
	id := p.Account.Id
	for _, e := range []eventbus.Event{
		verification.ProviderLevelChanged{ProviderID: id, From: 0, To: 1},
		verification.DocumentRejected{ProviderID: id, Item: verification.ItemSelfie, Reason: "Blurred"},
		verification.DocumentExpired{ProviderID: id, Item: verification.ItemPoliceClearance},
		verification.DocumentExpiring{ProviderID: id, Item: verification.ItemPoliceClearance, DaysLeft: 7},
		verification.Level2SessionScheduled{ProviderID: id, SessionID: uuid.New(), ScheduledAt: "2026-10-12T10:00:00Z", Location: "Gulshan"},
	} {
		a.Deliver(t, e)
	}
	got := inbox(t, a, "/v1/provider/notifications", auth)
	if len(got["items"].([]any)) != 5 {
		t.Fatalf("provider inbox: %v", got)
	}
	if body := got["items"].([]any)[3].(map[string]any)["body"].(string); body == "" {
		t.Fatal("empty body")
	}
	if r := a.Do(t, "GET", "/v1/provider/notifications?cursor=%25", nil, auth); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
	a.SeedCatalog(t)
	english := a.EnrolledProvider(t, "01712345642", "female", catalogapp.SeedID("service", "electrician"))
	if r := a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"language": "en"}, english.Auth()); r.Status != 200 {
		t.Fatalf("language: %d %s", r.Status, r.Body)
	}
	a.Deliver(t, verification.DocumentRejected{ProviderID: english.ID, Item: verification.ItemSelfie, Reason: "Blurred"})
	if got := inbox(t, a, "/v1/provider/notifications", english.Auth()); !strings.Contains(fmt.Sprint(got), "selfie") {
		t.Fatalf("english inbox: %v", got)
	}
	both := testkit.Bearer(a.Token(t, id, "provider", "customer"))
	device := map[string]string{"token": "device-token-closed", "platform": "web"}
	calls := []struct{ method, path string }{
		{"GET", "/v1/provider/notifications"}, {"GET", "/v1/customer/notifications"},
		{"POST", "/v1/customer/notifications/read-all"}, {"POST", "/v1/provider/notifications/read-all"},
		{"POST", "/v1/customer/notifications/" + uuid.NewString() + "/read"},
		{"PUT", "/v1/customer/device-token"}, {"PUT", "/v1/provider/device-token"},
	}
	for _, c := range calls {
		a.Do(t, c.method, c.path, device, both)
	}
	a.Infra.Pool.Close()
	for _, c := range calls {
		if r := a.Do(t, c.method, c.path, device, both); r.Status != 500 {
			t.Errorf("%s %s with closed pool: %d", c.method, c.path, r.Status)
		}
	}
	if err := a.Bus.Dispatch(context.Background(), a.Envelope(t, verification.DocumentExpired{ProviderID: id})); err == nil {
		t.Fatal("notification without a database")
	}
}
