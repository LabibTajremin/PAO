package api

import (
	"net/url"
	"testing"
	"time"
)

func TestExpiry_PoliceClearanceLapsesThenRenewalRestoresProvider(t *testing.T) {
	c := customer(t, phoneFor(t, "017", 31))
	svc, sub := service(t, c, "Electrician")
	// Issued a day short of the validity period, so it lapses tomorrow; every other
	// journey's clearance is a month old and stays valid past the sweep below.
	p := enrolledProvider(t, phoneFor(t, "018", 32), svc, time.Now().AddDate(0, 0, -364))
	approve(t, p, items...)
	goOnline(t, p)
	t.Cleanup(func() { do(t, "POST", "/v1/provider/presence/offline", nil, p) })
	eventually(t, 10*time.Second, "provider in nearby search", func() bool { return nearby(t, c, svc, sub, p.ID) })

	sweepAt := time.Now().AddDate(0, 0, 3).UTC().Format(time.RFC3339)
	if r := do(t, "POST", "/__test/verification/expire?at="+url.QueryEscape(sweepAt), nil, session{}); r.Status != 204 {
		t.Fatalf("expiry sweep: %d %s", r.Status, r.Body)
	}
	st := must(t, 200, "GET", "/v1/provider/verification", nil, p)
	if st["level"] != float64(0) || st["canReceiveBookings"] != false || itemStatus(st, "police_clearance") != "expired" {
		t.Fatalf("after expiry: %v", st)
	}
	eventually(t, 10*time.Second, "provider hidden from search", func() bool { return !nearby(t, c, svc, sub, p.ID) })
	if r := do(t, "POST", "/v1/provider/presence/online", map[string]any{"location": banani}, p); r.Status == 200 {
		t.Fatal("a provider with an expired clearance went online")
	}

	renewed := map[string]any{"mediaId": upload(t, p, "provider", "police_clearance"), "issueDate": time.Now().AddDate(0, 0, -7).Format(time.DateOnly)}
	must(t, 200, "PUT", "/v1/provider/enrolment/police-clearance", renewed, p)
	if st := must(t, 200, "GET", "/v1/provider/verification", nil, p); itemStatus(st, "police_clearance") != "pending" {
		t.Fatalf("renewal not in review: %v", st)
	}
	approve(t, p, "police_clearance")
	st = must(t, 200, "GET", "/v1/provider/verification", nil, p)
	if st["level"] != float64(1) || st["canReceiveBookings"] != true {
		t.Fatalf("after renewal: %v", st)
	}
	goOnline(t, p)
	eventually(t, 10*time.Second, "provider back in nearby search", func() bool { return nearby(t, c, svc, sub, p.ID) })
}

// itemStatus is the status of one verification item.
func itemStatus(status map[string]any, item string) string {
	for _, it := range status["items"].([]any) {
		if m := it.(map[string]any); m["type"] == item {
			return m["status"].(string)
		}
	}
	return ""
}
