//go:build integration

package http_test

import (
	"context"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func items(t *testing.T, r testkit.Response) []any {
	t.Helper()
	if r.Status != http.StatusOK {
		t.Fatalf("list: %d %s", r.Status, r.Body)
	}
	return r.JSON(t)["items"].([]any)
}

func TestPeople_ProvidersListDetailAndBan(t *testing.T) {
	a := testkit.NewAPI(t)
	j := a.CompletedJob(t, "01712345681", "01812345681")
	a.EnrolledProvider(t, "01712345682", "female", catalogapp.SeedID("service", "electrician"))
	support := testkit.Bearer(a.Admin(t, "support_agent").AccessToken)
	super := a.Admin(t, "super_admin")
	for query, want := range map[string]int{"": 2, "?status=pending": 1, "?status=active&level=1&flagged=false": 1, "?q=12345681": 1, "?q=nobody%25": 0} {
		if got := items(t, a.Do(t, "GET", "/v1/admin/providers"+query, nil, support)); len(got) != want {
			t.Errorf("providers%s: %d", query, len(got))
		}
	}
	first := a.Do(t, "GET", "/v1/admin/providers?limit=1", nil, support).JSON(t)
	rest := items(t, a.Do(t, "GET", "/v1/admin/providers?limit=1&cursor="+first["nextCursor"].(string), nil, support))
	if len(rest) != 1 || rest[0].(map[string]any)["id"] != j.Provider.ID.String() {
		t.Fatalf("second page: %v", rest)
	}
	path := "/v1/admin/providers/" + j.Provider.ID.String()
	d := a.Do(t, "GET", path, nil, support).JSON(t)
	sum := d["summary"].(map[string]any)
	if sum["status"] != "active" || sum["level"] != 1.0 || len(sum["services"].([]any)) != 1 || len(d["items"].([]any)) < 7 ||
		len(d["recentBookings"].([]any)) != 1 || d["gender"] != "male" || sum["online"] != true {
		t.Fatalf("detail: %v", d)
	}
	ban := map[string]any{"status": "banned", "reason": "Fraudulent documents"}
	r := a.Do(t, "POST", path+"/status", ban, testkit.Bearer(super.AccessToken))
	if r.Status != 200 || r.JSON(t)["summary"].(map[string]any)["status"] != "banned" {
		t.Fatalf("ban: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", path+"/status", ban, testkit.Bearer(super.AccessToken)); r.Code(t) != "CONFLICT" {
		t.Fatalf("ban twice: %s", r.Body)
	}
	a.RelayEvents(t)
	if r := a.Do(t, "GET", "/v1/provider/profile", nil, j.Provider.Auth()); r.Status != http.StatusUnauthorized {
		t.Fatalf("banned provider kept a session: %d", r.Status)
	}
	if got := items(t, a.Do(t, "GET", "/v1/admin/providers?status=banned", nil, support)); len(got) != 1 {
		t.Fatalf("banned list: %v", got)
	}
	d = a.Do(t, "GET", path, nil, support).JSON(t)
	if d["summary"].(map[string]any)["online"] != false {
		t.Fatal("banned provider still online")
	}
	if h := d["statusHistory"].([]any); len(h) != 1 || h[0].(map[string]any)["actorId"] != super.ID.String() {
		t.Fatalf("history: %v", d["statusHistory"])
	}
	back := a.Do(t, "POST", path+"/status", map[string]any{"status": "active", "reason": "Appeal accepted"}, testkit.Bearer(super.AccessToken))
	if back.JSON(t)["summary"].(map[string]any)["status"] != "active" {
		t.Fatalf("reinstate: %s", back.Body)
	}
	pending := items(t, a.Do(t, "GET", "/v1/admin/providers?status=pending", nil, support))[0].(map[string]any)["id"].(string)
	r = a.Do(t, "POST", "/v1/admin/providers/"+pending+"/status", map[string]any{"status": "suspended", "reason": "Checking"}, testkit.Bearer(super.AccessToken))
	if r.JSON(t)["summary"].(map[string]any)["status"] != "suspended" {
		t.Fatalf("suspend pending: %s", r.Body)
	}
	r = a.Do(t, "POST", "/v1/admin/providers/"+pending+"/status", map[string]any{"status": "active", "reason": "Checked"}, testkit.Bearer(super.AccessToken))
	if r.JSON(t)["summary"].(map[string]any)["status"] != "pending" {
		t.Fatalf("reinstate pending: %s", r.Body)
	}
	verifier := testkit.Bearer(a.Admin(t, "verifier").AccessToken)
	a.Do(t, "POST", "/v1/admin/verifications/"+pending+"/items/selfie/reject", map[string]string{"reason": "Face not visible"}, verifier)
	if r := a.Do(t, "GET", "/v1/admin/providers/"+pending, nil, support); !strings.Contains(string(r.Body), "Face not visible") {
		t.Fatalf("rejection reason missing: %s", r.Body)
	}
	for _, p := range []string{"/v1/admin/providers/" + uuid.NewString(), "/v1/admin/providers/" + j.Customer.ID.String()} {
		if r := a.Do(t, "GET", p, nil, support); r.Status != 404 {
			t.Errorf("%s: %d", p, r.Status)
		}
		if r := a.Do(t, "POST", p+"/status", ban, testkit.Bearer(super.AccessToken)); r.Status != 404 {
			t.Errorf("%s status: %d", p, r.Status)
		}
	}
	if r := a.Do(t, "GET", "/v1/admin/providers?cursor=%25", nil, support); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
	a.Infra.Pool.Close()
	for _, c := range []struct{ method, path string }{{"GET", "/v1/admin/providers"}, {"GET", path}, {"POST", path + "/status"}} {
		if r := a.Do(t, c.method, c.path, ban, testkit.Bearer(super.AccessToken)); r.Status != 500 {
			t.Errorf("%s %s closed pool: %d", c.method, c.path, r.Status)
		}
	}
}

func TestPeople_CustomersListDetailAndSuspend(t *testing.T) {
	a := testkit.NewAPI(t)
	j := a.CompletedJob(t, "01712345683", "01812345683")
	a.Customer(t, "01812345684")
	report(t, a, "/v1/customer/bookings/"+j.ID+"/reports", map[string]any{"reason": "late", "description": "Arrived two hours late."}, j.Customer.Auth())
	support := testkit.Bearer(a.Admin(t, "support_agent").AccessToken)
	super := testkit.Bearer(a.Admin(t, "super_admin").AccessToken)
	for query, want := range map[string]int{"": 2, "?q=nusrat": 2, "?q=12345684": 1, "?status=suspended": 0} {
		if got := items(t, a.Do(t, "GET", "/v1/admin/customers"+query, nil, support)); len(got) != want {
			t.Errorf("customers%s: %d", query, len(got))
		}
	}
	first := a.Do(t, "GET", "/v1/admin/customers?limit=1", nil, support).JSON(t)
	if rest := items(t, a.Do(t, "GET", "/v1/admin/customers?limit=1&cursor="+first["nextCursor"].(string), nil, support)); len(rest) != 1 {
		t.Fatalf("second page: %v", rest)
	}
	a.RelayEvents(t)
	path := "/v1/admin/customers/" + j.Customer.ID.String()
	d := a.Do(t, "GET", path, nil, support).JSON(t)
	if s := d["summary"].(map[string]any); s["bookings"] != 1.0 || s["status"] != "active" || len(d["recentBookings"].([]any)) != 1 || len(d["complaints"].([]any)) != 1 {
		t.Fatalf("detail: %v", d)
	}
	a.Do(t, "POST", "/v1/provider/jobs/"+j.ID+"/review", map[string]any{"stars": 4}, j.Provider.Auth())
	r := a.Do(t, "POST", path+"/status", map[string]any{"status": "suspended", "reason": "Abusive messages"}, super)
	if r.Status != 200 || r.JSON(t)["summary"].(map[string]any)["status"] != "suspended" || r.JSON(t)["summary"].(map[string]any)["rating"] != 4.0 {
		t.Fatalf("suspend: %d %s", r.Status, r.Body)
	}
	a.RelayEvents(t)
	if got := items(t, a.Do(t, "GET", "/v1/admin/customers?status=suspended", nil, support)); len(got) != 1 {
		t.Fatalf("suspended list: %v", got)
	}
	if r := a.Do(t, "POST", path+"/status", map[string]any{"status": "suspended", "reason": "Again"}, super); r.Status != 409 {
		t.Fatalf("suspend twice: %d", r.Status)
	}
	for _, p := range []string{"/v1/admin/customers/" + uuid.NewString(), "/v1/admin/customers/" + j.Provider.ID.String()} {
		if r := a.Do(t, "GET", p, nil, support); r.Status != 404 {
			t.Errorf("%s: %d", p, r.Status)
		}
		if r := a.Do(t, "POST", p+"/status", map[string]any{"status": "banned", "reason": "Nope"}, super); r.Status != 404 {
			t.Errorf("%s status: %d", p, r.Status)
		}
	}
	if r := a.Do(t, "GET", "/v1/admin/customers?cursor=%25", nil, support); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
	for _, name := range []string{booking.BookingRequested{}.EventName(), identity.AccountStatusChanged{}.EventName()} {
		if err := a.Bus.Dispatch(context.Background(), eventbus.Envelope{ID: uuid.New(), Name: name, Payload: []byte("{")}); err == nil {
			t.Errorf("%s accepted a broken payload", name)
		}
	}
	a.Infra.Pool.Close()
	for _, c := range []struct{ method, path string }{{"GET", "/v1/admin/customers"}, {"GET", path}, {"POST", path + "/status"}} {
		if r := a.Do(t, c.method, c.path, map[string]any{"status": "active", "reason": "Closed"}, super); r.Status != 500 {
			t.Errorf("%s %s closed pool: %d", c.method, c.path, r.Status)
		}
	}
}
