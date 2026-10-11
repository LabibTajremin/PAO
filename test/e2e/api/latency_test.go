package api

import (
	"slices"
	"testing"
	"time"
)

// TestLatency_RequestReachesProviderWithin3s checks PRD §11: a booking request reaches
// the provider's phone within 3 seconds. It measures from the create call returning to
// the push showing up in the worker's capture, over sequential requests.
func TestLatency_RequestReachesProviderWithin3s(t *testing.T) {
	const samples, limit = 10, 3 * time.Second
	c, address := customerAt(t, phoneFor(t, "017", 61))
	svc := catalogService(t, c, "Electrician")
	p := onlineProvider(t, 62, svc.ID)
	took := make([]time.Duration, 0, samples)
	for range samples {
		id := bookASAP(t, c, address, p.ID, svc.ID, line{svc.Subs[0], 1})["id"].(string)
		start := time.Now()
		for !pushed(t, p.PushToken, "booking_requested", id) {
			if time.Since(start) > 2*limit {
				t.Fatalf("no push for %s after %s", id, 2*limit)
			}
			time.Sleep(50 * time.Millisecond)
		}
		took = append(took, time.Since(start))
		// The customer may hold one open request per provider; close this one first.
		must(t, 200, "POST", "/v1/customer/bookings/"+id+"/cancel", map[string]string{"reason": "booked_by_mistake"}, c)
	}
	sorted := slices.Clone(took)
	slices.Sort(sorted)
	// With ten samples the 95th percentile is the slowest one.
	p95 := sorted[len(sorted)-1]
	t.Logf("request → push: %v (p95 %v)", took, p95)
	if p95 >= limit {
		t.Fatalf("p95 request → push %v, want under %v", p95, limit)
	}
}
