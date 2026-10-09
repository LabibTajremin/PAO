//go:build integration

package http_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

// both is the provider holding the customer role as well, to reach the other side's
// endpoints past RBAC.
func (w world) both(t *testing.T) testkit.Request {
	return testkit.Bearer(w.a.Token(t, w.provider.ID, "provider", "customer"))
}

func (w world) run(t *testing.T, id string) {
	t.Helper()
	w.job(t, id, "accept", nil)
	code := w.a.Do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, w.customer).JSON(t)["code"].(string)
	w.job(t, id, "on-the-way", nil)
	w.job(t, id, "arrived", nil)
	w.job(t, id, "start", map[string]string{"code": code})
}

func TestBooking_Edges(t *testing.T) {
	w := newWorld(t)
	a := w.a
	ctx := context.Background()
	both := w.both(t)
	id := w.book(t, "booking-edge-1", nil)
	for _, c := range []struct{ method, path string }{
		{"GET", "/v1/customer/bookings/" + id}, {"GET", "/v1/customer/bookings/" + id + "/start-code"},
	} {
		if r := a.Do(t, c.method, c.path, nil, both); r.Status != 404 {
			t.Errorf("provider on customer view %s: %d", c.path, r.Status)
		}
	}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+id+"/cancel", map[string]string{"reason": "other"}, both); r.Status != 404 {
		t.Errorf("provider cancelling as customer: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/provider/jobs/"+uuid.NewString()+"/accept", nil, w.provider.Auth()); r.Status != 404 {
		t.Errorf("unknown booking accept: %d", r.Status)
	}
	w.job(t, id, "reject", map[string]string{"reason": "busy"})
	if r := w.job(t, id, "reject", map[string]string{"reason": "busy"}); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Errorf("reject twice: %s", r.Body)
	}
	custView := testkit.Bearer(a.Token(t, w.custID, "customer", "provider"))
	second := w.book(t, "booking-edge-2", nil)
	if r := a.Do(t, "POST", "/v1/provider/jobs/"+second+"/accept", nil, custView); r.Status != 404 {
		t.Errorf("customer accepting: %d", r.Status)
	}
	w.run(t, second)
	if r := w.job(t, second, "on-the-way", nil); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Errorf("on the way after start: %s", r.Body)
	}
	extras := map[string]any{"items": []map[string]any{{"subServiceId": socket, "quantity": 1}}}
	p1 := w.job(t, second, "extras", extras).JSON(t)["pendingExtras"].(map[string]any)["id"]
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+second+"/extras/decision", map[string]any{"proposalId": p1, "approve": true}, both); r.Status != 404 {
		t.Errorf("provider deciding extras: %d", r.Status)
	}
	a.Do(t, "POST", "/v1/customer/bookings/"+second+"/extras/decision", map[string]any{"proposalId": p1, "approve": false}, w.customer)
	if r := w.job(t, second, "extras", extras); r.JSON(t)["pendingExtras"] == nil {
		t.Errorf("second proposal: %s", r.Body)
	}
	if _, err := a.Modules.Booking.Service.ProposeExtras(ctx, w.provider.ID, uuid.MustParse(second), nil); err == nil {
		t.Error("empty proposal")
	}
	if _, _, err := a.Modules.Booking.Service.Create(ctx, app.CreateInput{CustomerID: w.custID}); err == nil {
		t.Error("booking without a key")
	}
	in := w.appInput(electrician, fan)
	in.IdempotencyKey = "booking-direct-key"
	first, created, err := a.Modules.Booking.Service.Create(ctx, in)
	if err != nil || !created {
		t.Fatal(err)
	}
	again, created, err := a.Modules.Booking.Service.Create(ctx, in)
	if err != nil || created || again.ID != first.ID {
		t.Fatalf("replay: %v %v", created, err)
	}
	if _, err := a.Modules.Booking.Service.Cancel(ctx, "customer", w.custID, first.ID, "other"); err != nil {
		t.Fatal(err)
	}
	when := a.Clock.Now().Add(2 * time.Hour).UTC().Format(time.RFC3339)
	w.book(t, "booking-edge-scheduled", map[string]any{"timing": "scheduled", "scheduledAt": when,
		"items": []map[string]any{{"subServiceId": fan, "quantity": 1}}})
	up := a.Do(t, "GET", "/v1/customer/bookings?tab=upcoming", nil, w.customer).JSON(t)
	if len(up["items"].([]any)) < 2 {
		t.Errorf("upcoming: %v", up)
	}
}

func TestBooking_UnavailableAndEarningsPaging(t *testing.T) {
	w := newWorld(t)
	a := w.a
	ctx := context.Background()
	for i, key := range []string{"booking-earn-1", "booking-earn-2"} {
		id := w.book(t, key, nil)
		w.run(t, id)
		w.job(t, id, "complete", map[string]bool{"cashReceived": true})
		_ = i
	}
	page := a.Do(t, "GET", "/v1/provider/earnings/jobs?limit=1", nil, w.provider.Auth()).JSON(t)
	if len(page["items"].([]any)) != 1 || page["nextCursor"] == nil {
		t.Fatalf("earnings page: %v", page)
	}
	next := a.Do(t, "GET", "/v1/provider/earnings/jobs?limit=1&cursor="+page["nextCursor"].(string), nil, w.provider.Auth()).JSON(t)
	if len(next["items"].([]any)) != 1 {
		t.Fatalf("earnings page 2: %v", next)
	}
	near := "/v1/customer/providers/nearby?serviceId=" + electrician.String() + "&subServiceId=" + fan.String() + "&quantity=1&addressId=" + w.address
	a.Do(t, "POST", "/v1/provider/presence/offline", nil, w.provider.Auth())
	if r := a.Do(t, "POST", "/v1/customer/bookings", w.body(nil), w.customer, testkit.Header("Idempotency-Key", "booking-offline")); r.Code(t) != "PROVIDER_UNAVAILABLE" {
		t.Fatalf("offline provider: %s", r.Body)
	}
	if _, err := a.Infra.Pool.Exec(ctx, "UPDATE catalog.services SET published = false WHERE id = $1", electrician); err != nil {
		t.Fatal(err)
	}
	if r := a.Do(t, "GET", near, nil, w.customer); r.Code(t) != "PROVIDER_UNAVAILABLE" {
		t.Fatalf("unpublished nearby: %s", r.Body)
	}
	if r := a.Do(t, "POST", "/v1/customer/bookings", w.body(nil), w.customer, testkit.Header("Idempotency-Key", "booking-unpublished")); r.Code(t) != "PROVIDER_UNAVAILABLE" {
		t.Fatalf("unpublished service: %s", r.Body)
	}
	a.Infra.Redis.Del(ctx, a.Infra.Keys.Key("cache", "settings"))
	if _, err := a.Infra.Pool.Exec(ctx, "ALTER TABLE admin.settings RENAME TO gone"); err != nil {
		t.Fatal(err)
	}
	if _, err := a.Modules.Booking.Service.Start(ctx, w.provider.ID, uuid.New(), "1234"); err == nil {
		t.Fatal("start without settings")
	}
	a.Infra.Pool.Close()
	if r := a.Do(t, "GET", "/v1/customer/bookings/"+uuid.NewString(), nil, w.customer); r.Status != 500 {
		t.Fatalf("detail with closed pool: %d", r.Status)
	}
}
