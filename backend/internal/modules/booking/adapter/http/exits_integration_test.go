//go:build integration

package http_test

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestBooking_RejectTimeoutCancel(t *testing.T) {
	w := newWorld(t)
	a := w.a
	ctx := context.Background()
	rejected := w.book(t, "booking-reject", nil)
	if r := w.job(t, rejected, "reject", map[string]string{"reason": "busy", "note": "Another job"}); r.JSON(t)["status"] != "rejected" {
		t.Fatalf("reject: %s", r.Body)
	}
	timedOut := w.book(t, "booking-timeout", nil)
	a.Clock.Advance(3 * time.Minute)
	if err := inproc.NewExpireWorker(a.Modules.Booking.Service).Work(ctx, nil); err != nil {
		t.Fatal(err)
	}
	w.provider.Token = a.Token(t, w.provider.ID, "provider")
	w.customer = testkit.Bearer(a.Token(t, w.custID, "customer"))
	if r := a.Do(t, "GET", "/v1/customer/bookings/"+timedOut, nil, w.customer); r.JSON(t)["status"] != "timed_out" {
		t.Fatalf("timeout: %s", r.Body)
	}
	if r := w.job(t, timedOut, "accept", nil); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("accept timed out: %s", r.Body)
	}
	free := w.book(t, "booking-cancel-free", nil)
	cancel := map[string]string{"reason": "changed_mind"}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+free+"/cancel", cancel, w.customer); r.JSON(t)["status"] != "cancelled" {
		t.Fatalf("cancel requested: %s", r.Body)
	}
	if r := w.job(t, free, "cancel", map[string]string{"reason": "emergency"}); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("provider cancels cancelled: %s", r.Body)
	}
	byProvider := w.book(t, "booking-cancel-provider", nil)
	w.job(t, byProvider, "accept", nil)
	if r := w.job(t, byProvider, "cancel", map[string]string{"reason": "emergency"}); r.JSON(t)["status"] != "cancelled" {
		t.Fatalf("provider cancel: %s", r.Body)
	}
	started := w.book(t, "booking-started", nil)
	w.job(t, started, "accept", nil)
	code := a.Do(t, "GET", "/v1/customer/bookings/"+started+"/start-code", nil, w.customer).JSON(t)["code"].(string)
	w.job(t, started, "on-the-way", nil)
	w.job(t, started, "arrived", nil)
	w.job(t, started, "start", map[string]string{"code": code})
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+started+"/cancel", cancel, w.customer); r.Code(t) != "CANCELLATION_NOT_ALLOWED" {
		t.Fatalf("cancel started: %s", r.Body)
	}
	a.RelayEvents(t)
	stats, _ := a.Modules.Booking.Contract.GetProviderStats(ctx, w.provider.ID)
	if stats.Cancellations30d != 1 {
		t.Fatalf("provider cancellations: %+v", stats)
	}
	if n, _ := a.Modules.Booking.Contract.CountActiveJobs(ctx, w.provider.ID); n != 1 {
		t.Fatalf("active jobs: %d", n)
	}
	up := a.Do(t, "GET", "/v1/provider/jobs?tab=upcoming", nil, w.provider.Auth()).JSON(t)
	past := a.Do(t, "GET", "/v1/provider/jobs?tab=past&limit=2", nil, w.provider.Auth()).JSON(t)
	if len(up["items"].([]any)) != 1 || len(past["items"].([]any)) != 2 || past["nextCursor"] == nil {
		t.Fatalf("lists: %v %v", up, past)
	}
	more := a.Do(t, "GET", "/v1/provider/jobs?tab=past&limit=2&cursor="+past["nextCursor"].(string), nil, w.provider.Auth()).JSON(t)
	if len(more["items"].([]any)) != 2 {
		t.Fatalf("page 2: %v", more)
	}
	a.Modules.Booking.RegisterJobs(jobs.NewRegistry())
}

func TestBooking_IdempotencyAndConcurrentAccepts(t *testing.T) {
	w := newWorld(t)
	a := w.a
	first := w.book(t, "booking-same-key", nil)
	if again := w.book(t, "booking-same-key", nil); again != first {
		t.Fatalf("same key made a new booking: %s %s", first, again)
	}
	r := a.Do(t, "POST", "/v1/customer/bookings", w.body(nil), w.customer, testkit.Header("Idempotency-Key", "booking-other-key"))
	if r.Code(t) != "DUPLICATE_BOOKING_REQUEST" {
		t.Fatalf("second open request: %s", r.Body)
	}
	if r := a.Modules.Booking.Service; r == nil {
		t.Fatal("no service")
	}
	var wg sync.WaitGroup
	statuses := make(chan int, 5)
	for range 5 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			statuses <- w.job(t, first, "accept", nil).Status
		}()
	}
	wg.Wait()
	close(statuses)
	won := 0
	for s := range statuses {
		if s == 200 {
			won++
		}
	}
	if won != 1 {
		t.Fatalf("%d accepts won", won)
	}
	asap := w.book(t, "booking-second-asap", nil)
	if r := w.job(t, asap, "accept", nil); r.Code(t) != "ACTIVE_JOB_EXISTS" {
		t.Fatalf("second ASAP job: %s", r.Body)
	}
	w.job(t, asap, "reject", map[string]string{"reason": "busy"})
	when := a.Clock.Now().Add(24 * time.Hour).UTC().Format(time.RFC3339)
	scheduled := w.book(t, "booking-scheduled", map[string]any{"timing": "scheduled", "scheduledAt": when})
	if r := w.job(t, scheduled, "accept", nil); r.JSON(t)["status"] != "accepted" {
		t.Fatalf("scheduled with an active job: %s", r.Body)
	}
}
