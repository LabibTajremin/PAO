package api

import (
	"fmt"
	"strconv"
	"testing"
	"time"
)

func TestBooking_FromRequestToReceiptWithExtrasAndRatings(t *testing.T) {
	c, address := customerAt(t, phoneFor(t, "017", 11))
	electrician := catalogService(t, c, "Electrician")
	if len(electrician.Subs) < 2 {
		t.Fatalf("electrician needs two sub-services for extras: %v", electrician)
	}
	fan, extra := electrician.Subs[0], electrician.Subs[1]
	p := onlineProvider(t, 12, electrician.ID)
	eventually(t, 10*time.Second, "provider in nearby search", func() bool { return nearby(t, c, electrician.ID, fan.ID, p.ID) })

	id := requestAndAccept(t, c, address, p, electrician.ID, fan)
	arriveAndStartAfterTwoWrongCodes(t, c, p, id)
	total := addApprovedExtras(t, c, p, id, 2*fan.Price, extra)

	if r := job(t, p, id, "complete", map[string]bool{"cashReceived": false}); r.Code(t) != "CASH_CONFIRMATION_REQUIRED" {
		t.Fatalf("complete without cash: %d %s", r.Status, r.Body)
	}
	done := mustJob(t, p, id, "complete", map[string]bool{"cashReceived": true})
	if done["status"] != "completed" || done["total"] != float64(total) {
		t.Fatalf("completed: %v", done)
	}
	rateBothWays(t, c, p, id)
	checkReceipts(t, c, p, id, total, line{fan, 2}, line{extra, 1})
	checkEarnings(t, p, id, total)
}

// requestAndAccept books two of sub with p, checks the provider was paged and that
// contact details are shared only after acceptance; it returns the booking ID.
func requestAndAccept(t *testing.T, c session, address string, p partner, serviceID string, fan sub) string {
	t.Helper()
	b := bookASAP(t, c, address, p.ID, serviceID, line{fan, 2})
	id := b["id"].(string)
	if b["total"] != float64(2*fan.Price) || b["timing"] != "asap" {
		t.Fatalf("booking: %v", b)
	}
	eventually(t, 10*time.Second, "request pushed to the provider", func() bool { return pushed(t, p.PushToken, "booking_requested", id) })
	request := must(t, 200, "GET", "/v1/provider/jobs/"+id, nil, p.session)
	if request["address"].(map[string]any)["line1"] != nil || request["customer"].(map[string]any)["phone"] != nil {
		t.Fatalf("contact details shared before acceptance: %v", request)
	}
	if r := do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, c); r.Code(t) != "BOOKING_INVALID_TRANSITION" {
		t.Fatalf("start code before acceptance: %d %s", r.Status, r.Body)
	}
	accepted := mustJob(t, p, id, "accept", nil)
	if accepted["status"] != "accepted" || accepted["address"].(map[string]any)["line1"] == nil || accepted["customer"].(map[string]any)["phone"] == nil {
		t.Fatalf("accepted: %v", accepted)
	}
	seen := must(t, 200, "GET", "/v1/customer/bookings/"+id, nil, c)
	if seen["status"] != "accepted" || seen["provider"].(map[string]any)["phone"] == nil {
		t.Fatalf("customer view after acceptance: %v", seen)
	}
	return id
}

// arriveAndStartAfterTwoWrongCodes walks on the way → arrived, enters two wrong start
// codes, then the right one.
func arriveAndStartAfterTwoWrongCodes(t *testing.T, c session, p partner, id string) {
	t.Helper()
	code := startCode(t, c, id)
	mustJob(t, p, id, "on-the-way", nil)
	if s := customerStatus(t, c, id); s != "on_the_way" {
		t.Fatalf("customer sees %s, want on_the_way", s)
	}
	mustJob(t, p, id, "arrived", nil)
	n, _ := strconv.Atoi(code)
	for i := 1; i <= 2; i++ {
		wrong := fmt.Sprintf("%04d", (n+i)%10000)
		if r := job(t, p, id, "start", map[string]string{"code": wrong}); r.Code(t) != "START_CODE_INVALID" {
			t.Fatalf("wrong code %d: %d %s", i, r.Status, r.Body)
		}
	}
	if s := customerStatus(t, c, id); s != "arrived" {
		t.Fatalf("after wrong codes: %s", s)
	}
	if b := mustJob(t, p, id, "start", map[string]string{"code": code}); b["status"] != "in_progress" {
		t.Fatalf("right code: %v", b)
	}
}

// addApprovedExtras has p propose one extra item and c approve it; completing is
// refused while the proposal is pending. It returns the new total.
func addApprovedExtras(t *testing.T, c session, p partner, id string, before int64, extra sub) int64 {
	t.Helper()
	proposed := mustJob(t, p, id, "extras", map[string]any{"items": lines(line{extra, 1})})
	pending := proposed["pendingExtras"].(map[string]any)
	total := before + extra.Price
	if pending["addedTotal"] != float64(extra.Price) || pending["newTotal"] != float64(total) || pending["status"] != "pending" {
		t.Fatalf("proposal: %v", pending)
	}
	if r := job(t, p, id, "complete", map[string]bool{"cashReceived": true}); r.Code(t) != "EXTRAS_PENDING" {
		t.Fatalf("complete with extras pending: %d %s", r.Status, r.Body)
	}
	decided := must(t, 200, "POST", "/v1/customer/bookings/"+id+"/extras/decision",
		map[string]any{"proposalId": pending["id"], "approve": true}, c)
	if decided["total"] != float64(total) || len(decided["items"].([]any)) != 2 {
		t.Fatalf("approved extras: %v", decided)
	}
	return total
}

// rateBothWays has each side review the other; the provider's rating follows.
func rateBothWays(t *testing.T, c session, p partner, id string) {
	t.Helper()
	review(t, c, "/v1/customer/bookings/"+id+"/review",
		map[string]any{"stars": 5, "tags": []string{"on_time", "professional"}, "comment": "Fixed the fan quickly."})
	review(t, p.session, "/v1/provider/jobs/"+id+"/review", map[string]any{"stars": 4, "tags": []string{"polite", "paid_promptly"}})
	if r := do(t, "POST", "/v1/customer/bookings/"+id+"/review", map[string]any{"stars": 1}, c); r.Status != 409 {
		t.Fatalf("second review: %d %s", r.Status, r.Body)
	}
	if b := must(t, 200, "GET", "/v1/customer/bookings/"+id, nil, c); b["reviewedByMe"] != true {
		t.Fatalf("reviewedByMe: %v", b["reviewedByMe"])
	}
	eventually(t, 10*time.Second, "provider rating updated", func() bool {
		r := must(t, 200, "GET", "/v1/provider/rating", nil, p.session)
		return r["count"] == float64(1) && r["average"] == float64(5)
	})
}

// review posts a review once the booking is reviewable: the rating module learns of
// the completion from the worker's relay a moment after the API answered.
func review(t *testing.T, s session, path string, body any) {
	t.Helper()
	eventually(t, 10*time.Second, "review accepted", func() bool {
		r := do(t, "POST", path, body, s)
		if r.Status != 201 && r.Code(t) != "REVIEW_NOT_ALLOWED" {
			t.Fatalf("review %s: %d %s", path, r.Status, r.Body)
		}
		return r.Status == 201
	})
}

// checkReceipts compares both receipts with the booked and the extra lines.
func checkReceipts(t *testing.T, c session, p partner, id string, total int64, booked, extra line) {
	t.Helper()
	for _, path := range []string{"/v1/customer/bookings/" + id + "/receipt", "/v1/provider/jobs/" + id + "/receipt"} {
		who := c
		if path[4:12] == "provider" {
			who = p.session
		}
		rc := must(t, 200, "GET", path, nil, who)
		if rc["total"] != float64(total) || rc["paymentMethod"] != "cash" || rc["providerName"] != "Rahim Uddin" || rc["customerName"] != "Nusrat Jahan" {
			t.Fatalf("%s: %v", path, rc)
		}
		got := rc["items"].([]any)
		if len(got) != 2 {
			t.Fatalf("%s items: %v", path, got)
		}
		for i, want := range []struct {
			l     line
			extra bool
		}{{booked, false}, {extra, true}} {
			it := got[i].(map[string]any)
			if it["subServiceId"] != want.l.Sub.ID || it["quantity"] != float64(want.l.Quantity) || it["extra"] != want.extra ||
				it["unitPrice"] != float64(want.l.Sub.Price) || it["total"] != float64(want.l.Sub.Price*int64(want.l.Quantity)) {
				t.Fatalf("%s item %d: %v", path, i, it)
			}
		}
	}
}

// checkEarnings expects the completed job to be the provider's only earning.
func checkEarnings(t *testing.T, p partner, id string, total int64) {
	t.Helper()
	sum := must(t, 200, "GET", "/v1/provider/earnings/summary?period=week", nil, p.session)
	if sum["total"] != float64(total) || sum["jobs"] != float64(1) || len(sum["buckets"].([]any)) != 7 {
		t.Fatalf("earnings summary: %v", sum)
	}
	jobs := must(t, 200, "GET", "/v1/provider/earnings/jobs", nil, p.session)["items"].([]any)
	if len(jobs) != 1 || jobs[0].(map[string]any)["bookingId"] != id || jobs[0].(map[string]any)["total"] != float64(total) {
		t.Fatalf("earnings jobs: %v", jobs)
	}
}
