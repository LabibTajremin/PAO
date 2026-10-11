package api

import (
	"testing"
	"time"
)

func TestOnboarding_EnrolApproveGoOnlineAndBeFound(t *testing.T) {
	c := customer(t, phoneFor(t, "017", 1))
	svc, sub := service(t, c, "Electrician")
	p := enrolledProvider(t, phoneFor(t, "018", 2), svc, time.Now().AddDate(0, -1, 0))
	if r := do(t, "POST", "/v1/provider/presence/online", map[string]any{"location": banani}, p); r.Status == 200 {
		t.Fatal("an unverified provider went online")
	}
	approve(t, p, items...)
	status := must(t, 200, "GET", "/v1/provider/verification", nil, p)
	if status["level"] != float64(1) || status["canReceiveBookings"] != true {
		t.Fatalf("after approval: %v", status)
	}
	goOnline(t, p)
	eventually(t, 10*time.Second, "provider in nearby search", func() bool { return nearby(t, c, svc, sub, p.ID) })
}
