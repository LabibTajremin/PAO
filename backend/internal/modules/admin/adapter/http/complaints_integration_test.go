//go:build integration

package http_test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func report(t *testing.T, a *testkit.API, path string, body map[string]any, who testkit.Request) map[string]any {
	t.Helper()
	r := a.Do(t, "POST", path, body, who)
	if r.Status != 201 {
		t.Fatalf("report %s: %d %s", path, r.Status, r.Body)
	}
	return r.JSON(t)
}

func TestComplaints_ReportedByBothSidesAndResolved(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	j := a.RequestedJob(t, "01712345661", "01812345661")
	photo := a.Upload(t, j.Customer.ID, "customer", "complaint_photo")
	late := map[string]any{"reason": "late", "description": "Arrived two hours late.", "photoMediaIds": []string{photo.String()}}
	mine := report(t, a, "/v1/customer/bookings/"+j.ID+"/reports", late, j.Customer.Auth())
	if !strings.HasPrefix(mine["ticketNumber"].(string), "TCK-") || mine["againstId"] != j.Provider.ID.String() || mine["status"] != "open" ||
		len(mine["photoMediaIds"].([]any)) != 1 {
		t.Fatalf("customer report: %v", mine)
	}
	theirs := report(t, a, "/v1/provider/jobs/"+j.ID+"/reports", map[string]any{"reason": "customer_unavailable", "description": "Nobody answered the door."}, j.Provider.Auth())
	if theirs["againstId"] != j.Customer.ID.String() || theirs["reporterRole"] != "provider" {
		t.Fatalf("provider report: %v", theirs)
	}
	stranger, _ := a.Customer(t, "01812345662")
	for name, c := range map[string]struct {
		path string
		body map[string]any
		who  testkit.Request
		code string
	}{
		"stranger":             {"/v1/customer/bookings/" + j.ID + "/reports", late, stranger.Auth(), "NOT_FOUND"},
		"unknown booking":      {"/v1/customer/bookings/" + uuid.NewString() + "/reports", late, j.Customer.Auth(), "NOT_FOUND"},
		"provider as customer": {"/v1/customer/bookings/" + j.ID + "/reports", late, testkit.Bearer(a.Token(t, j.Provider.ID, "customer")), "NOT_FOUND"},
		"blank description": {"/v1/customer/bookings/" + j.ID + "/reports", map[string]any{"reason": "late", "description": "    late     "},
			j.Customer.Auth(), "VALIDATION_FAILED"},
		"used photo": {"/v1/provider/jobs/" + j.ID + "/reports", late, j.Provider.Auth(), "UPLOAD_INVALID"},
		"unknown photo": {"/v1/customer/bookings/" + j.ID + "/reports", map[string]any{"reason": "late", "description": late["description"],
			"photoMediaIds": []string{uuid.NewString()}}, j.Customer.Auth(), "UPLOAD_INVALID"},
	} {
		if r := a.Do(t, "POST", c.path, c.body, c.who); r.Code(t) != c.code {
			t.Errorf("%s: %d %s", name, r.Status, r.Body)
		}
	}
	agent := a.Admin(t, "support_agent")
	resolved := resolve(t, a, agent, mine["id"].(string))
	if resolved["status"] != "resolved" || resolved["verified"] != true || len(resolved["comments"].([]any)) != 1 {
		t.Fatalf("resolved: %v", resolved)
	}
	a.RelayEvents(t)
	var flagged bool
	if err := a.Infra.Pool.QueryRow(ctx, "SELECT flagged_for_review FROM provider.providers WHERE id = $1", j.Provider.ID).Scan(&flagged); err != nil || !flagged {
		t.Fatalf("verified complaint did not flag the provider: %v", err)
	}
	if n, err := a.Modules.Admin.Contract.CountVerifiedComplaints(ctx, j.Provider.ID); err != nil || n != 1 {
		t.Fatalf("verified count: %d %v", n, err)
	}
	inbox := a.Do(t, "GET", "/v1/customer/notifications", nil, j.Customer.Auth()).JSON(t)
	if !strings.Contains(fmt.Sprint(inbox), "Your report "+mine["ticketNumber"].(string)+" has been resolved.") {
		t.Fatalf("reporter not told: %v", inbox)
	}
	entries, err := a.Modules.Audit.Contract.ListForSubject(ctx, "complaint", mine["id"].(string), 10)
	if err != nil || len(entries) != 1 || entries[0].Action != "complaint.resolved" || *entries[0].ActorID != agent.ID {
		t.Fatalf("audit: %+v %v", entries, err)
	}
}

func resolve(t *testing.T, a *testkit.API, agent testkit.AdminSession, id string) map[string]any {
	t.Helper()
	auth := testkit.Bearer(agent.AccessToken)
	base := "/v1/admin/complaints/" + id
	if r := a.Do(t, "POST", base+"/assign", map[string]any{"assigneeId": agent.ID}, auth); r.Status != 200 || r.JSON(t)["assigneeId"] != agent.ID.String() {
		t.Fatalf("assign: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", base+"/comments", map[string]any{"body": "Called the provider."}, auth); r.Status != 201 {
		t.Fatalf("comment: %d %s", r.Status, r.Body)
	}
	r := a.Do(t, "POST", base+"/resolve", map[string]any{"resolution": "Provider warned; partial refund agreed.", "verified": true}, auth)
	if r.Status != 200 {
		t.Fatalf("resolve: %d %s", r.Status, r.Body)
	}
	if again := a.Do(t, "POST", base+"/resolve", map[string]any{"resolution": "Second attempt.", "verified": false}, auth); again.Code(t) != "COMPLAINT_INVALID_TRANSITION" {
		t.Fatalf("resolve twice: %s", again.Body)
	}
	if again := a.Do(t, "POST", base+"/assign", map[string]any{"assigneeId": agent.ID}, auth); again.Status != 409 {
		t.Fatalf("assign resolved: %s", again.Body)
	}
	return r.JSON(t)
}

func TestComplaints_QueueFiltersAndErrors(t *testing.T) {
	a := testkit.NewAPI(t)
	j := a.RequestedJob(t, "01712345663", "01812345663")
	for _, reason := range []string{"late", "overcharge", "damage"} {
		report(t, a, "/v1/customer/bookings/"+j.ID+"/reports", map[string]any{"reason": reason, "description": "Something went wrong here."}, j.Customer.Auth())
	}
	agent := a.Admin(t, "support_agent")
	auth := testkit.Bearer(agent.AccessToken)
	first := a.Do(t, "GET", "/v1/admin/complaints?status=open&limit=2", nil, auth).JSON(t)
	items := first["items"].([]any)
	if len(items) != 2 || items[0].(map[string]any)["reason"] != "damage" || first["nextCursor"] == nil {
		t.Fatalf("first page: %v", first)
	}
	rest := a.Do(t, "GET", "/v1/admin/complaints?status=open&limit=2&cursor="+first["nextCursor"].(string), nil, auth).JSON(t)
	if len(rest["items"].([]any)) != 1 || rest["nextCursor"] != nil {
		t.Fatalf("second page: %v", rest)
	}
	id := items[0].(map[string]any)["id"].(string)
	customer := map[string]any{"assigneeId": j.Customer.ID}
	for name, c := range map[string]struct {
		method, path string
		body         any
		status       int
	}{
		"assign customer":   {"POST", "/v1/admin/complaints/" + id + "/assign", customer, 422},
		"assign unknown id": {"POST", "/v1/admin/complaints/" + id + "/assign", map[string]any{"assigneeId": uuid.New()}, 422},
		"assign missing":    {"POST", "/v1/admin/complaints/" + uuid.NewString() + "/assign", map[string]any{"assigneeId": agent.ID}, 404},
		"comment missing":   {"POST", "/v1/admin/complaints/" + uuid.NewString() + "/comments", map[string]any{"body": "x"}, 404},
		"resolve missing":   {"POST", "/v1/admin/complaints/" + uuid.NewString() + "/resolve", map[string]any{"resolution": "Done here.", "verified": false}, 404},
		"resolve short":     {"POST", "/v1/admin/complaints/" + id + "/resolve", map[string]any{"resolution": "  ok   ", "verified": false}, 422},
		"get missing":       {"GET", "/v1/admin/complaints/" + uuid.NewString(), nil, 404},
		"bad cursor":        {"GET", "/v1/admin/complaints?cursor=%25", nil, 422},
	} {
		if r := a.Do(t, c.method, c.path, c.body, auth); r.Status != c.status {
			t.Errorf("%s: %d %s", name, r.Status, r.Body)
		}
	}
	a.Do(t, "POST", "/v1/admin/complaints/"+id+"/assign", map[string]any{"assigneeId": agent.ID}, auth)
	mine := a.Do(t, "GET", "/v1/admin/complaints?assigneeId="+agent.ID.String(), nil, auth).JSON(t)
	if got := a.Do(t, "GET", "/v1/admin/complaints/"+id, nil, auth).JSON(t); len(mine["items"].([]any)) != 1 || got["status"] != "assigned" {
		t.Fatalf("assigned queue: %v %v", mine, got)
	}
	closedPool(t, a, j, auth, id)
}

func closedPool(t *testing.T, a *testkit.API, j testkit.Job, auth testkit.Request, id string) {
	t.Helper()
	body := map[string]any{"reason": "late", "description": "Arrived two hours late.", "assigneeId": uuid.New(), "body": "note",
		"resolution": "Closed now.", "verified": false}
	calls := []struct {
		method, path string
		who          testkit.Request
	}{
		{"POST", "/v1/customer/bookings/" + j.ID + "/reports", j.Customer.Auth()},
		{"GET", "/v1/admin/complaints", auth}, {"GET", "/v1/admin/complaints/" + id, auth},
		{"POST", "/v1/admin/complaints/" + id + "/assign", auth}, {"POST", "/v1/admin/complaints/" + id + "/comments", auth},
		{"POST", "/v1/admin/complaints/" + id + "/resolve", auth},
	}
	a.Infra.Pool.Close()
	for _, c := range calls {
		if r := a.Do(t, c.method, c.path, body, c.who); r.Status != 500 {
			t.Errorf("%s %s with closed pool: %d %s", c.method, c.path, r.Status, r.Body)
		}
	}
}
