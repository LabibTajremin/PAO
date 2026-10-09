//go:build integration

package http_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestBooking_OwnershipContractAndFailures(t *testing.T) {
	w := newWorld(t)
	a := w.a
	ctx := context.Background()
	photo := a.Upload(t, w.provider.ID, "provider", "avatar")
	a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"language": "bn", "photoMediaId": photo}, w.provider.Auth())
	near := a.Do(t, "GET", "/v1/customer/providers/nearby?serviceId="+electrician.String()+"&subServiceId="+fan.String()+"&quantity=1&addressId="+w.address, nil, w.customer).JSON(t)
	if near["items"].([]any)[0].(map[string]any)["photoUrl"] == nil {
		t.Fatalf("card photo: %v", near)
	}
	id := w.book(t, "booking-owner-1", nil)
	other := a.VerifiedProvider(t, "01712345688", "male", electrician)
	for _, action := range []string{"reject", "on-the-way", "arrived"} {
		if r := a.Do(t, "POST", "/v1/provider/jobs/"+id+"/"+action, map[string]string{"reason": "busy"}, other.Auth()); r.Status != 404 {
			t.Errorf("%s by another provider: %d", action, r.Status)
		}
	}
	for _, path := range []string{"/v1/provider/jobs/" + id, "/v1/provider/jobs/" + id + "/receipt"} {
		if r := a.Do(t, "GET", path, nil, other.Auth()); r.Status != 404 {
			t.Errorf("%s by another provider: %d", path, r.Status)
		}
	}
	if r := a.Do(t, "GET", "/v1/provider/jobs/"+id, nil, w.customer); r.Status != 403 && r.Status != 404 {
		t.Errorf("customer reading the provider view: %d", r.Status)
	}
	stranger := testkit.Bearer(a.Token(t, uuid.New(), "customer"))
	if r := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, stranger); r.Status != 404 {
		t.Errorf("stranger start code: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+id+"/cancel", map[string]string{"reason": "other"}, stranger); r.Status != 404 {
		t.Errorf("stranger cancel: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+id+"/extras/decision", map[string]any{"proposalId": uuid.New(), "approve": true}, stranger); r.Status != 404 {
		t.Errorf("stranger decision: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/provider/jobs/"+id+"/extras", map[string]any{"items": []map[string]any{{"subServiceId": fan, "quantity": 1}}}, w.provider.Auth()); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Errorf("extras before start: %s", r.Body)
	}
	b, err := a.Modules.Booking.Contract.GetBooking(ctx, uuid.MustParse(id))
	if err != nil || b.Status != contract.StatusRequested || b.CustomerName != "Nusrat Jahan" || b.Number == "" {
		t.Fatalf("contract booking: %+v %v", b, err)
	}
	if _, err := a.Modules.Booking.Contract.GetBooking(ctx, uuid.New()); !errors.Is(err, contract.ErrBookingNotFound) {
		t.Fatal(err)
	}
	recent, err := a.Modules.Booking.Contract.ListRecentBookings(ctx, w.provider.ID, 5)
	if err != nil || len(recent) != 1 {
		t.Fatalf("recent: %+v %v", recent, err)
	}
	if r := a.Do(t, "GET", "/v1/provider/earnings/summary?period=day&date=2026-01-01", nil, w.provider.Auth()); r.JSON(t)["jobs"] != float64(0) {
		t.Fatalf("earnings by date: %s", r.Body)
	}
	if r := a.Do(t, "GET", "/v1/provider/earnings/jobs?from=2026-01-01&to=2026-12-31&limit=1", nil, w.provider.Auth()); r.Status != 200 {
		t.Fatalf("earnings jobs range: %d", r.Status)
	}
	for _, path := range []string{"/v1/customer/bookings?tab=past&cursor=%25", "/v1/provider/jobs?tab=past&cursor=%25", "/v1/provider/earnings/jobs?cursor=%25"} {
		tok := w.provider.Auth()
		if path[4:12] == "customer" {
			tok = w.customer
		}
		if r := a.Do(t, "GET", path, nil, tok); r.Status != 422 {
			t.Errorf("%s: %d", path, r.Status)
		}
	}
	a.Infra.Pool.Close()
	for _, c := range []struct {
		path string
		tok  testkit.Request
	}{
		{"/v1/customer/bookings?tab=upcoming", w.customer}, {"/v1/provider/jobs?tab=requests", w.provider.Auth()},
		{"/v1/provider/earnings/jobs", w.provider.Auth()}, {"/v1/provider/earnings/summary?period=month", w.provider.Auth()},
	} {
		if r := a.Do(t, "GET", c.path, nil, c.tok); r.Status != 500 {
			t.Errorf("%s with closed pool: %d", c.path, r.Status)
		}
	}
	if err := a.Modules.Booking.Service.ExpireDue(ctx); err == nil {
		t.Fatal("expiry without a database")
	}
	if _, err := a.Modules.Booking.Contract.ListRecentBookings(ctx, w.provider.ID, 5); err == nil {
		t.Fatal("recent without a database")
	}
}
