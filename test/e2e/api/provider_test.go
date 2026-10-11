package api

import (
	"fmt"
	"net/http"
	"net/url"
	"testing"
	"time"
)

// banani is where every e2e provider works and every e2e customer lives.
var banani = map[string]float64{"lat": 23.7937, "lng": 90.4066}

// items are the Level 1 verification items a verifier approves.
var items = []string{"nid", "selfie", "police_clearance", "address", "emergency_contact", "service_area", "code_of_conduct"}

// offer is a seeded service with its sub-services in catalog order.
type offer struct {
	ID   string
	Subs []sub
}

// sub is a sub-service with its current price in paisa.
type sub struct {
	ID    string
	Price int64
}

// catalogService finds a seeded service by English name in the customer catalog.
func catalogService(t *testing.T, s session, name string) offer {
	t.Helper()
	tree := must(t, 200, "GET", "/v1/customer/catalog", nil, s)
	for _, c := range tree["categories"].([]any) {
		for _, sv := range c.(map[string]any)["services"].([]any) {
			svc := sv.(map[string]any)
			if svc["name"].(map[string]any)["en"] != name {
				continue
			}
			o := offer{ID: svc["id"].(string)}
			for _, it := range svc["subServices"].([]any) {
				ss := it.(map[string]any)
				o.Subs = append(o.Subs, sub{ID: ss["id"].(string), Price: int64(ss["price"].(float64))})
			}
			return o
		}
	}
	t.Fatalf("no service %q", name)
	return offer{}
}

// service finds a seeded service by English name and its first sub-service.
func service(t *testing.T, s session, name string) (serviceID, subServiceID string) {
	t.Helper()
	o := catalogService(t, s, name)
	return o.ID, o.Subs[0].ID
}

// enrolledProvider signs a partner-app user in, completes every enrolment step with
// documents and submits it; policeIssued dates the police clearance.
func enrolledProvider(t *testing.T, phone, serviceID string, policeIssued time.Time) session {
	t.Helper()
	p := signIn(t, phone, "partner")
	contact := "019" + phone[len(phone)-8:]
	steps := []struct {
		path string
		body any
	}{
		{"/v1/provider/enrolment/personal", map[string]any{"fullName": "Rahim Uddin", "dateOfBirth": "1990-04-12", "gender": "male",
			"presentAddress": "House 12, Banani", "permanentAddress": "Cumilla Sadar"}},
		{"/v1/provider/enrolment/services", map[string]any{"serviceIds": []string{serviceID}, "experienceYears": 8}},
		{"/v1/provider/enrolment/area", map[string]any{"homeBase": banani, "workingRadiusM": 8000}},
		{"/v1/provider/enrolment/code-of-conduct", map[string]any{"version": "2026-10", "accepted": true}},
		{"/v1/provider/enrolment/emergency-contact", map[string]string{"name": "Karim Uddin", "relation": "Brother", "phone": contact}},
		{"/v1/provider/enrolment/nid", map[string]any{"nidNumber": "1" + phone[len(phone)-9:],
			"frontMediaId": upload(t, p, "provider", "nid_front"), "backMediaId": upload(t, p, "provider", "nid_back")}},
		{"/v1/provider/enrolment/selfie", map[string]any{"mediaId": upload(t, p, "provider", "selfie")}},
		{"/v1/provider/enrolment/police-clearance", map[string]any{"mediaId": upload(t, p, "provider", "police_clearance"),
			"issueDate": policeIssued.Format("2006-01-02")}},
	}
	for _, s := range steps {
		must(t, 200, "PUT", s.path, s.body, p)
	}
	must(t, 200, "POST", "/v1/provider/enrolment/emergency-contact/verify", map[string]string{"code": lastCode(t, contact)}, p)
	must(t, 200, "POST", "/v1/provider/enrolment/submit", nil, p)
	return p
}

// approve has the seeded verifier approve each item of p's submission, once the
// worker has relayed the submission and every item waits for review.
func approve(t *testing.T, p session, which ...string) {
	t.Helper()
	v := admin(t, "verifier@pao.bd")
	eventually(t, 10*time.Second, "items pending review", func() bool {
		pending := map[string]bool{}
		for _, it := range must(t, 200, "GET", "/v1/admin/verifications/"+p.ID, nil, v)["items"].([]any) {
			item := it.(map[string]any)
			pending[item["type"].(string)] = item["status"] == "pending"
		}
		for _, item := range which {
			if !pending[item] {
				return false
			}
		}
		return true
	})
	for _, item := range which {
		path := fmt.Sprintf("/v1/admin/verifications/%s/items/%s/approve", p.ID, item)
		// One verifier approves every provider of the suite; back-to-back runs can pass
		// the per-user limit of 120 calls a minute, so wait for the window to slide.
		eventually(t, 70*time.Second, "approval within the rate limit", func() bool {
			r := do(t, "POST", path, nil, v)
			if r.Status != http.StatusOK && r.Status != http.StatusTooManyRequests {
				t.Fatalf("POST %s: %d %s", path, r.Status, r.Body)
			}
			return r.Status == http.StatusOK
		})
	}
}

// goOnline waits for the approved level to reach the provider module (the worker
// relays it), then brings the provider online in Banani.
func goOnline(t *testing.T, p session) {
	t.Helper()
	eventually(t, 10*time.Second, "provider allowed online", func() bool {
		return do(t, "POST", "/v1/provider/presence/online", map[string]any{"location": banani}, p).Status == 200
	})
}

// nearby reports whether customer c finds provider p for the sub-service, reading
// every page: providers of earlier runs may still be online at the same spot.
func nearby(t *testing.T, c session, serviceID, subServiceID, providerID string) bool {
	t.Helper()
	q := fmt.Sprintf("/v1/customer/providers/nearby?serviceId=%s&subServiceId=%s&quantity=1&lat=%v&lng=%v",
		serviceID, subServiceID, banani["lat"], banani["lng"])
	for page := q; ; {
		res := must(t, 200, "GET", page, nil, c)
		for _, it := range res["items"].([]any) {
			if it.(map[string]any)["id"] == providerID {
				return true
			}
		}
		next, _ := res["nextCursor"].(string)
		if next == "" {
			return false
		}
		page = q + "&cursor=" + url.QueryEscape(next)
	}
}
