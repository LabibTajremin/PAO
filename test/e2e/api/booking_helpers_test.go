package api

import (
	"fmt"
	"net/http"
	"net/url"
	"testing"
	"time"
)

// partner is an approved, online provider whose phone registered a push token.
type partner struct {
	session
	Phone     string
	PushToken string
}

// onlineProvider enrols a provider for serviceID, has every item approved, registers
// a device for pushes and brings them online; they go offline when the test ends so
// later runs do not page through them in nearby search.
func onlineProvider(t *testing.T, n int, serviceID string) partner {
	t.Helper()
	phone := phoneFor(t, "018", n)
	p := partner{session: enrolledProvider(t, phone, serviceID, time.Now().AddDate(0, -1, 0)), Phone: phone}
	approve(t, p.session, items...)
	p.PushToken = fmt.Sprintf("e2e-push-%s-%d", phone, time.Now().UnixNano())
	must(t, 204, "PUT", "/v1/provider/device-token", map[string]string{"token": p.PushToken, "platform": "android"}, p.session)
	goOnline(t, p.session)
	t.Cleanup(func() { do(t, "POST", "/v1/provider/presence/offline", nil, p.session) })
	return p
}

// line is one item of a booking request.
type line struct {
	Sub      sub
	Quantity int
}

func lines(ls ...line) []map[string]any {
	out := make([]map[string]any, len(ls))
	for i, l := range ls {
		out[i] = map[string]any{"subServiceId": l.Sub.ID, "quantity": l.Quantity}
	}
	return out
}

// bookASAP has customer c request an ASAP booking with provider p at the address,
// with a fresh idempotency key, and returns the created booking.
func bookASAP(t *testing.T, c session, address, providerID, serviceID string, ls ...line) map[string]any {
	t.Helper()
	body := map[string]any{"providerId": providerID, "serviceId": serviceID, "timing": "asap", "addressId": address,
		"items": lines(ls...), "note": "Second floor"}
	key := fmt.Sprintf("e2e-%s-%d", c.ID, time.Now().UnixNano())
	b := must(t, 201, "POST", "/v1/customer/bookings", body, c, "Idempotency-Key", key)
	if b["status"] != "requested" {
		t.Fatalf("new booking: %v", b)
	}
	return b
}

// job sends a provider action ("accept", "on-the-way", "start", ...) on a booking.
func job(t *testing.T, p partner, bookingID, action string, body any) response {
	t.Helper()
	return do(t, "POST", "/v1/provider/jobs/"+bookingID+"/"+action, body, p.session)
}

// mustJob is job that fails unless the action succeeds, returning the booking.
func mustJob(t *testing.T, p partner, bookingID, action string, body any) map[string]any {
	t.Helper()
	return must(t, 200, "POST", "/v1/provider/jobs/"+bookingID+"/"+action, body, p.session)
}

// startJob takes an accepted booking to in_progress with the customer's start code.
func startJob(t *testing.T, c session, p partner, bookingID string) {
	t.Helper()
	code := startCode(t, c, bookingID)
	mustJob(t, p, bookingID, "on-the-way", nil)
	mustJob(t, p, bookingID, "arrived", nil)
	if b := mustJob(t, p, bookingID, "start", map[string]string{"code": code}); b["status"] != "in_progress" {
		t.Fatalf("start: %v", b)
	}
}

// startCode is the code the customer reads out to the provider on arrival.
func startCode(t *testing.T, c session, bookingID string) string {
	t.Helper()
	return must(t, 200, "GET", "/v1/customer/bookings/"+bookingID+"/start-code", nil, c)["code"].(string)
}

// customerStatus is the booking status the customer sees.
func customerStatus(t *testing.T, c session, bookingID string) string {
	t.Helper()
	return must(t, 200, "GET", "/v1/customer/bookings/"+bookingID, nil, c)["status"].(string)
}

// pushed reports whether the worker sent a push of the template about the booking to
// the device token.
func pushed(t *testing.T, token, template, bookingID string) bool {
	t.Helper()
	r := call(t, stack.worker, "GET", "/__test/pushes?token="+url.QueryEscape(token), nil, session{})
	if r.Status != http.StatusOK {
		t.Fatalf("pushes: %d %s", r.Status, r.Body)
	}
	for _, p := range r.JSON(t)["pushes"].([]any) {
		data, _ := p.(map[string]any)["data"].(map[string]any)
		if data["type"] == template && data["bookingId"] == bookingID {
			return true
		}
	}
	return false
}

// setSetting changes an admin setting as the super admin and restores the old value
// when the test ends, so a failing test cannot leave the stack reconfigured.
func setSetting(t *testing.T, key, value string) {
	t.Helper()
	super := admin(t, "super@pao.bd")
	old := ""
	for _, it := range must(t, 200, "GET", "/v1/admin/settings", nil, super)["items"].([]any) {
		if s := it.(map[string]any); s["key"] == key {
			old = s["value"].(string)
		}
	}
	if old == "" {
		t.Fatalf("no setting %s", key)
	}
	must(t, 200, "PUT", "/v1/admin/settings/"+key, map[string]string{"value": value}, super)
	t.Cleanup(func() { must(t, 200, "PUT", "/v1/admin/settings/"+key, map[string]string{"value": old}, super) })
}
