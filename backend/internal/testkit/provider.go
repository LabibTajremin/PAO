package testkit

import (
	"bytes"
	"context"
	"net/http"
	"testing"

	"github.com/google/uuid"
)

// Upload stores a small confirmed file for owner with the given purpose and returns its
// media ID, going through the presigned URL like an app would.
func (a *API) Upload(t testing.TB, owner uuid.UUID, uploader, purpose string) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	body := []byte("file")
	ticket, err := a.Modules.Media.Service.CreateUpload(ctx, owner, uploader, purpose, "image/jpeg", int64(len(body)))
	if err != nil {
		t.Fatalf("upload %s: %v", purpose, err)
	}
	req, _ := http.NewRequest(http.MethodPut, ticket.URL, bytes.NewReader(body))
	for k, v := range ticket.Headers {
		req.Header.Set(k, v)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil || res.StatusCode != http.StatusOK {
		t.Fatalf("put %s: %v %v", purpose, res, err)
	}
	_ = res.Body.Close()
	if _, err := a.Modules.Media.Service.Confirm(ctx, owner, ticket.MediaID); err != nil {
		t.Fatalf("confirm %s: %v", purpose, err)
	}
	return ticket.MediaID
}

// ProviderSession is an enrolled provider.
type ProviderSession struct {
	ID    uuid.UUID
	Token string
}

// Auth returns the provider's bearer option.
func (p ProviderSession) Auth() Request { return Bearer(p.Token) }

// ok fails the test unless the request returned 200.
func (a *API) ok(t testing.TB, method, path string, body any, opts ...Request) {
	t.Helper()
	r := a.Do(t, method, path, body, opts...)
	if r.Status != http.StatusOK {
		t.Fatalf("%s %s: %d %s", method, path, r.Status, r.Body)
	}
}

// EnrolledProvider signs a partner-app user in, completes every enrolment step with
// documents and submits it. The emergency contact is phone with "019" in front of its
// last eight digits.
func (a *API) EnrolledProvider(t testing.TB, phone, gender string, services ...uuid.UUID) ProviderSession {
	t.Helper()
	tp := a.SignIn(t, phone, "partner")
	p := ProviderSession{ID: tp.Account.Id, Token: tp.AccessToken}
	contact := "019" + phone[len(phone)-8:]
	steps := []struct {
		path string
		body any
	}{
		{"/v1/provider/enrolment/personal", map[string]any{"fullName": "Rahim Uddin", "dateOfBirth": "1990-04-12", "gender": gender,
			"presentAddress": "House 12, Banani", "permanentAddress": "Cumilla Sadar"}},
		{"/v1/provider/enrolment/services", map[string]any{"serviceIds": services, "experienceYears": 8}},
		{"/v1/provider/enrolment/area", map[string]any{"homeBase": map[string]float64{"lat": 23.7937, "lng": 90.4066}, "workingRadiusM": 8000}},
		{"/v1/provider/enrolment/code-of-conduct", map[string]any{"version": "2026-10", "accepted": true}},
		{"/v1/provider/enrolment/emergency-contact", map[string]string{"name": "Karim Uddin", "relation": "Brother", "phone": contact}},
		{"/v1/provider/enrolment/nid", map[string]any{"nidNumber": "1" + phone[len(phone)-9:], "frontMediaId": a.Upload(t, p.ID, "provider", "nid_front"),
			"backMediaId": a.Upload(t, p.ID, "provider", "nid_back")}},
		{"/v1/provider/enrolment/selfie", map[string]any{"mediaId": a.Upload(t, p.ID, "provider", "selfie")}},
		{"/v1/provider/enrolment/police-clearance", map[string]any{"mediaId": a.Upload(t, p.ID, "provider", "police_clearance"),
			"issueDate": a.Clock.Now().AddDate(0, -1, 0).Format("2006-01-02")}},
	}
	for _, s := range steps {
		a.ok(t, "PUT", s.path, s.body, p.Auth())
	}
	a.ok(t, "POST", "/v1/provider/enrolment/emergency-contact/verify", map[string]string{"code": a.LastCode(t, contact)}, p.Auth())
	a.ok(t, "POST", "/v1/provider/enrolment/submit", nil, p.Auth())
	a.RelayEvents(t)
	return p
}

// VerifiedProvider enrols a provider and has a verifier approve every submitted item,
// leaving them at Level 1.
func (a *API) VerifiedProvider(t testing.TB, phone, gender string, services ...uuid.UUID) ProviderSession {
	t.Helper()
	p := a.EnrolledProvider(t, phone, gender, services...)
	verifier := Bearer(a.Admin(t, "verifier").AccessToken)
	for _, item := range []string{"nid", "selfie", "police_clearance", "address", "emergency_contact", "service_area", "code_of_conduct"} {
		a.ok(t, "POST", "/v1/admin/verifications/"+p.ID.String()+"/items/"+item+"/approve", nil, verifier)
	}
	a.RelayEvents(t)
	return p
}
