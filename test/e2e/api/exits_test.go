package api

import (
	"testing"
	"time"
)

// exitWorld is a customer next to an online electrician, ready to book.
type exitWorld struct {
	c       session
	address string
	p       partner
	svc     offer
}

func newExitWorld(t *testing.T, n int) exitWorld {
	t.Helper()
	c, address := customerAt(t, phoneFor(t, "017", n))
	svc := catalogService(t, c, "Electrician")
	return exitWorld{c: c, address: address, p: onlineProvider(t, n+1, svc.ID), svc: svc}
}

func (w exitWorld) book(t *testing.T) string {
	t.Helper()
	return bookASAP(t, w.c, w.address, w.p.ID, w.svc.ID, line{w.svc.Subs[0], 1})["id"].(string)
}

func TestBooking_ProviderRejectsAndCustomerSeesIt(t *testing.T) {
	w := newExitWorld(t, 21)
	id := w.book(t)
	if r := job(t, w.p, id, "reject", map[string]string{}); r.Status != 422 {
		t.Fatalf("reject without a reason: %d %s", r.Status, r.Body)
	}
	if b := mustJob(t, w.p, id, "reject", map[string]string{"reason": "too_far"}); b["status"] != "rejected" {
		t.Fatalf("reject: %v", b)
	}
	b := must(t, 200, "GET", "/v1/customer/bookings/"+id, nil, w.c)
	if b["status"] != "rejected" || b["cancellable"] != false {
		t.Fatalf("customer view of a rejected request: %v", b)
	}
	if r := job(t, w.p, id, "accept", nil); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("accept after reject: %d %s", r.Status, r.Body)
	}
	// A rejected request is closed, so the customer may ask the same provider again.
	w.book(t)
}

func TestBooking_UnansweredRequestTimesOut(t *testing.T) {
	w := newExitWorld(t, 23)
	setSetting(t, "booking.accept_timeout_asap_seconds", "1")
	id := w.book(t)
	// The worker sweeps expired requests every 15 seconds.
	eventually(t, 40*time.Second, "request timed out", func() bool { return customerStatus(t, w.c, id) == "timed_out" })
	if r := job(t, w.p, id, "accept", nil); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("accept after timeout: %d %s", r.Status, r.Body)
	}
	eventually(t, 10*time.Second, "missed request pushed", func() bool { return pushed(t, w.p.PushToken, "request_missed", id) })
}

func TestBooking_CustomerCancelsBeforeStart(t *testing.T) {
	w := newExitWorld(t, 25)
	cancel := map[string]string{"reason": "changed_mind"}
	requested := w.book(t)
	if b := must(t, 200, "POST", "/v1/customer/bookings/"+requested+"/cancel", cancel, w.c); b["status"] != "cancelled" {
		t.Fatalf("cancel a request: %v", b)
	}
	accepted := w.book(t)
	mustJob(t, w.p, accepted, "accept", nil)
	mustJob(t, w.p, accepted, "on-the-way", nil)
	if b := must(t, 200, "POST", "/v1/customer/bookings/"+accepted+"/cancel", cancel, w.c); b["status"] != "cancelled" {
		t.Fatalf("cancel on the way: %v", b)
	}
	if j := must(t, 200, "GET", "/v1/provider/jobs/"+accepted, nil, w.p.session); j["status"] != "cancelled" {
		t.Fatalf("provider view: %v", j)
	}
	eventually(t, 10*time.Second, "cancellation pushed", func() bool { return pushed(t, w.p.PushToken, "booking_cancelled", accepted) })
}

func TestBooking_CancellationBlockedOnceStarted(t *testing.T) {
	w := newExitWorld(t, 27)
	id := w.book(t)
	mustJob(t, w.p, id, "accept", nil)
	startJob(t, w.c, w.p, id)
	r := do(t, "POST", "/v1/customer/bookings/"+id+"/cancel", map[string]string{"reason": "changed_mind"}, w.c)
	if r.Status != 409 || r.Code(t) != "CANCELLATION_NOT_ALLOWED" {
		t.Fatalf("customer cancel after start: %d %s", r.Status, r.Body)
	}
	if r := job(t, w.p, id, "cancel", map[string]string{"reason": "emergency"}); r.Status != 409 {
		t.Fatalf("provider cancel after start: %d %s", r.Status, r.Body)
	}
	if b := must(t, 200, "GET", "/v1/customer/bookings/"+id, nil, w.c); b["status"] != "in_progress" || b["cancellable"] != false {
		t.Fatalf("after refused cancels: %v", b)
	}
	mustJob(t, w.p, id, "complete", map[string]bool{"cashReceived": true})
}
