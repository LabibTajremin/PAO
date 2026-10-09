//go:build integration

package http_test

import (
	"context"
	"fmt"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestDashboard_CountsFromEvents(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	done := a.CompletedJob(t, "01712345671", "01812345671")
	open := a.RequestedJob(t, "01712345672", "01812345672")
	a.EnrolledProvider(t, "01712345673", "female", catalogapp.SeedID("service", "electrician"))
	for _, id := range []uuid.UUID{open.Provider.ID, open.Customer.ID} {
		if _, err := a.Modules.Identity.Contract.SetAccountStatus(ctx, identity.SetAccountStatusInput{AccountID: id, Status: identity.StatusSuspended, Reason: "Testing"}); err != nil {
			t.Fatal(err)
		}
	}
	report(t, a, "/v1/customer/bookings/"+done.ID+"/reports", map[string]any{"reason": "late", "description": "Arrived two hours late."}, done.Customer.Auth())
	a.RelayEvents(t)
	a.Deliver(t, identity.AccountDeleted{AccountID: uuid.New()})
	if err := a.Bus.Dispatch(ctx, eventbus.Envelope{ID: uuid.New(), Name: identity.AccountCreated{}.EventName(), Payload: []byte("{")}); err == nil {
		t.Fatal("broken payload accepted")
	}
	auth := testkit.Bearer(a.Admin(t, "support_agent").AccessToken)
	d := a.Do(t, "GET", "/v1/admin/dashboard", nil, auth).JSON(t)
	days := d["bookingsPerDay"].([]any)
	today := days[len(days)-1].(map[string]any)
	want := "map[active:1 pending:1 suspended:1] map[0:1 1:2] 0.5 1 1"
	if got := fmt.Sprint(d["providersByStatus"], " ", d["providersByLevel"], " ", d["completionRate"], " ", d["openComplaints"], " ", d["pendingVerifications"]); got != want ||
		len(days) != 30 || today["total"] != 2.0 || today["completed"] != 1.0 || today["date"] != a.Clock.Now().In(clock.Dhaka).Format("2006-01-02") {
		t.Fatalf("dashboard: %s\n%v", got, d)
	}
	a.Infra.Pool.Close()
	if r := a.Do(t, "GET", "/v1/admin/dashboard", nil, auth); r.Status != 200 {
		t.Fatalf("cached dashboard: %d", r.Status)
	}
	if _, err := a.Infra.Redis.Del(ctx, a.Infra.Keys.Key("cache", "dashboard")).Result(); err != nil {
		t.Fatal(err)
	}
	if r := a.Do(t, "GET", "/v1/admin/dashboard", nil, auth); r.Status != 500 {
		t.Fatalf("closed pool: %d", r.Status)
	}
}
