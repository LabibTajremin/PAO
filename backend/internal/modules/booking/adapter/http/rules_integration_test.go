//go:build integration

package http_test

import (
	"context"
	"strconv"
	"testing"
	"time"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestBooking_CreateRules(t *testing.T) {
	w := newWorld(t)
	a := w.a
	n := 0
	key := func() testkit.Request {
		n++
		return testkit.Header("Idempotency-Key", "booking-rules-"+strconv.Itoa(n))
	}
	past := a.Clock.Now().Add(-time.Hour).UTC().Format(time.RFC3339)
	cases := []struct {
		extra map[string]any
		code  string
	}{
		{map[string]any{"timing": "scheduled"}, "VALIDATION_FAILED"},
		{map[string]any{"timing": "scheduled", "scheduledAt": past}, "VALIDATION_FAILED"},
		{map[string]any{"items": []map[string]any{{"subServiceId": tap, "quantity": 1}}}, "VALIDATION_FAILED"},
		{map[string]any{"items": []map[string]any{{"subServiceId": fan, "quantity": 11}}}, "VALIDATION_FAILED"},
		{map[string]any{"items": []map[string]any{{"subServiceId": uuid.New(), "quantity": 1}}}, "VALIDATION_FAILED"},
		{map[string]any{"serviceId": uuid.New()}, "NOT_FOUND"},
		{map[string]any{"addressId": uuid.New()}, "VALIDATION_FAILED"},
		{map[string]any{"providerId": uuid.New()}, "PROVIDER_UNAVAILABLE"},
	}
	for _, c := range cases {
		if r := a.Do(t, "POST", "/v1/customer/bookings", w.body(c.extra), w.customer, key()); r.Code(t) != c.code {
			t.Errorf("%v: %d %s", c.extra, r.Status, r.Body)
		}
	}
	stranger := testkit.Bearer(a.Token(t, uuid.New(), "customer"))
	if r := a.Do(t, "POST", "/v1/customer/bookings", w.body(nil), stranger, key()); r.Code(t) != "PROFILE_REQUIRED" {
		t.Fatalf("no profile: %s", r.Body)
	}
	area := `{"type":"Polygon","coordinates":[[[91,22],[92,22],[92,23],[91,22]]]}`
	super := testkit.Bearer(a.Admin(t, "super_admin").AccessToken)
	a.Do(t, "PUT", "/v1/admin/settings/service_area.geojson", map[string]string{"value": area}, super)
	if r := a.Do(t, "POST", "/v1/customer/bookings", w.body(nil), w.customer, key()); r.Code(t) != "OUTSIDE_SERVICE_AREA" {
		t.Fatalf("outside area: %s", r.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/providers/nearby?serviceId="+electrician.String()+"&subServiceId="+fan.String()+"&quantity=1&lat=23.79&lng=90.40", nil, w.customer); r.Code(t) != "OUTSIDE_SERVICE_AREA" {
		t.Fatalf("nearby outside area: %s", r.Body)
	}
	a.Do(t, "PUT", "/v1/admin/settings/service_area.geojson", map[string]string{"value": ""}, super)
	if r := a.Do(t, "GET", "/v1/customer/providers/nearby?serviceId="+electrician.String()+"&subServiceId="+fan.String()+"&quantity=1&sort=rating&lat=23.79&lng=90.40", nil, w.customer); len(r.JSON(t)["items"].([]any)) != 1 {
		t.Fatalf("nearby by point: %s", r.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/providers/nearby?serviceId="+electrician.String()+"&subServiceId="+fan.String()+"&quantity=1", nil, w.customer); r.Status != 422 {
		t.Fatalf("nearby without a place: %d", r.Status)
	}
	if r := a.Do(t, "GET", "/v1/customer/bookings/"+uuid.NewString(), nil, w.customer); r.Status != 404 {
		t.Fatalf("unknown booking: %d", r.Status)
	}
}

func TestBooking_StartCodeLockoutAndDurationHire(t *testing.T) {
	w := newWorld(t)
	a := w.a
	id := w.book(t, "booking-lockout", nil)
	w.job(t, id, "accept", nil)
	code := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, w.customer).JSON(t)["code"].(string)
	wrong := "0000"
	if code == wrong {
		wrong = "1111"
	}
	if r := w.job(t, id, "start", map[string]string{"code": code}); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("start before arrival: %s", r.Body)
	}
	w.job(t, id, "on-the-way", nil)
	w.job(t, id, "arrived", nil)
	for range 5 {
		w.job(t, id, "start", map[string]string{"code": wrong})
	}
	if r := w.job(t, id, "start", map[string]string{"code": code}); r.Code(t) != "START_CODE_LOCKED" {
		t.Fatalf("locked: %s", r.Body)
	}
	a.Clock.Advance(10 * time.Minute)
	w.provider.Token = a.Token(t, w.provider.ID, "provider")
	if r := w.job(t, id, "start", map[string]string{"code": code}); r.JSON(t)["status"] != "in_progress" {
		t.Fatalf("after lockout: %s", r.Body)
	}
	if r := w.job(t, id, "extras", map[string]any{"items": []map[string]any{{"subServiceId": tap, "quantity": 1}}}); r.Code(t) != "VALIDATION_FAILED" {
		t.Fatalf("extras from another service: %s", r.Body)
	}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+id+"/extras/decision", map[string]any{"proposalId": uuid.New(), "approve": true}, testkit.Bearer(a.Token(t, w.custID, "customer"))); r.Code(t) != "NO_PENDING_EXTRAS" {
		t.Fatalf("decide nothing: %s", r.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/receipt", nil, testkit.Bearer(a.Token(t, w.custID, "customer"))); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("receipt before completion: %s", r.Body)
	}
	driver := catalogapp.SeedID("service", "driver")
	b, _, err := a.Modules.Booking.Service.Create(context.Background(), w.appInput(driver, catalogapp.SeedID("sub-service", "driver-day")))
	if err == nil || b.EndsAt != nil {
		t.Fatalf("driver booking with an electrician: %v", err)
	}
	driverPro := a.VerifiedProvider(t, "01712345699", "male", driver)
	a.Do(t, "POST", "/v1/provider/presence/online", online, driverPro.Auth())
	in := w.appInput(driver, catalogapp.SeedID("sub-service", "driver-day"))
	in.ProviderID = driverPro.ID
	b, created, err := a.Modules.Booking.Service.Create(context.Background(), in)
	if err != nil || !created || b.EndsAt == nil || b.EndsAt.Sub(b.CreatedAt) != 24*time.Hour {
		t.Fatalf("duration hire: %+v %v", b, err)
	}
}
