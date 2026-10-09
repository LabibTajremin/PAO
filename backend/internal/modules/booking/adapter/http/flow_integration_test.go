//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestBooking_HappyPathWithExtras(t *testing.T) {
	w := newWorld(t)
	a := w.a
	ctx := context.Background()
	nr := a.Do(t, "GET", "/v1/customer/providers/nearby?serviceId="+electrician.String()+"&subServiceId="+fan.String()+"&quantity=2&addressId="+w.address, nil, w.customer)
	if nr.Status != 200 {
		t.Fatalf("nearby: %d %s", nr.Status, nr.Body)
	}
	near := nr.JSON(t)
	if len(near["items"].([]any)) != 1 || near["priceSummary"].(map[string]any)["total"] != float64(100000) {
		t.Fatalf("nearby: %v", near)
	}
	id := w.book(t, "booking-key-1", nil)
	before := a.Do(t, "GET", "/v1/provider/jobs/"+id, nil, w.provider.Auth()).JSON(t)
	if before["address"].(map[string]any)["line1"] != nil || before["customer"].(map[string]any)["phone"] != nil {
		t.Fatalf("address shared before acceptance: %v", before)
	}
	if r := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, w.customer); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("code before acceptance: %s", r.Body)
	}
	accepted := w.job(t, id, "accept", nil).JSON(t)
	if accepted["status"] != "accepted" || accepted["address"].(map[string]any)["line1"] != "House 12, Road 5" || accepted["customer"].(map[string]any)["phone"] == nil {
		t.Fatalf("accepted: %v", accepted)
	}
	code := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, w.customer).JSON(t)["code"].(string)
	w.job(t, id, "on-the-way", nil)
	w.job(t, id, "arrived", nil)
	if r := w.job(t, id, "start", map[string]string{"code": "0000"}); code != "0000" && r.Code(t) != "START_CODE_INVALID" {
		t.Fatalf("wrong code: %s", r.Body)
	}
	if r := w.job(t, id, "start", map[string]string{"code": code}); r.JSON(t)["status"] != "in_progress" {
		t.Fatalf("start: %s", r.Body)
	}
	extras := w.job(t, id, "extras", map[string]any{"items": []map[string]any{{"subServiceId": socket, "quantity": 1}}}).JSON(t)
	pending := extras["pendingExtras"].(map[string]any)
	if pending["addedTotal"] != float64(35000) || pending["newTotal"] != float64(135000) {
		t.Fatalf("extras: %v", extras)
	}
	if r := w.job(t, id, "complete", map[string]bool{"cashReceived": true}); r.Code(t) != "EXTRAS_PENDING" {
		t.Fatalf("complete with pending extras: %s", r.Body)
	}
	decision := map[string]any{"proposalId": pending["id"], "approve": true}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+id+"/extras/decision", decision, w.customer); r.JSON(t)["total"] != float64(135000) {
		t.Fatalf("decide: %s", r.Body)
	}
	if r := w.job(t, id, "complete", map[string]bool{"cashReceived": false}); r.Code(t) != "CASH_CONFIRMATION_REQUIRED" {
		t.Fatalf("cash: %s", r.Body)
	}
	done := w.job(t, id, "complete", map[string]bool{"cashReceived": true}).JSON(t)
	if done["status"] != "completed" || len(done["items"].([]any)) != 2 || len(done["timeline"].([]any)) != 6 {
		t.Fatalf("complete: %v", done)
	}
	rc := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/receipt", nil, w.customer).JSON(t)
	if rc["total"] != float64(135000) || rc["providerName"] != "Rahim Uddin" {
		t.Fatalf("receipt: %v", rc)
	}
	if r := a.Do(t, "GET", "/v1/provider/jobs/"+id+"/receipt", nil, w.provider.Auth()); r.Status != 200 {
		t.Fatalf("provider receipt: %d", r.Status)
	}
	sum := a.Do(t, "GET", "/v1/provider/earnings/summary?period=week", nil, w.provider.Auth()).JSON(t)
	if sum["total"] != float64(135000) || sum["jobs"] != float64(1) || len(sum["buckets"].([]any)) != 7 {
		t.Fatalf("earnings: %v", sum)
	}
	if jobs := a.Do(t, "GET", "/v1/provider/earnings/jobs", nil, w.provider.Auth()).JSON(t); len(jobs["items"].([]any)) != 1 {
		t.Fatalf("earnings jobs: %v", jobs)
	}
	if past := a.Do(t, "GET", "/v1/customer/bookings?tab=past", nil, w.customer).JSON(t); len(past["items"].([]any)) != 1 {
		t.Fatalf("past: %v", past)
	}
	a.RelayEvents(t)
	stats, err := a.Modules.Booking.Contract.GetProviderStats(ctx, w.provider.ID)
	if err != nil || stats.CompletedJobs != 1 {
		t.Fatalf("stats: %+v %v", stats, err)
	}
	_ = testkit.Bearer
}
