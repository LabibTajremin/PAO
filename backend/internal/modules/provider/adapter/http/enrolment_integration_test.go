//go:build integration

package http_test

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

const phone = "01712345678"

var (
	electrician = catalogapp.SeedID("service", "electrician")
	homeSalon   = catalogapp.SeedID("service", "home-salon")
	banani      = map[string]float64{"lat": 23.7937, "lng": 90.4066}
)

func personal(gender string) map[string]any {
	return map[string]any{"fullName": "Rahim Uddin", "dateOfBirth": "1990-04-12", "gender": gender,
		"presentAddress": "House 12, Banani", "permanentAddress": "Cumilla Sadar", "bio": "Electrician"}
}

// enrol completes every profile step for a new partner-app user.
func enrol(t *testing.T, a *testkit.API, p, gender string, services ...uuid.UUID) (uuid.UUID, testkit.Request) {
	t.Helper()
	tp := a.SignIn(t, p, "partner")
	auth := testkit.Bearer(tp.AccessToken)
	steps := []struct {
		path string
		body any
	}{
		{"/v1/provider/enrolment/personal", personal(gender)},
		{"/v1/provider/enrolment/services", map[string]any{"serviceIds": services, "experienceYears": 8}},
		{"/v1/provider/enrolment/area", map[string]any{"homeBase": banani, "workingRadiusM": 8000}},
		{"/v1/provider/enrolment/code-of-conduct", map[string]any{"version": "2026-10", "accepted": true}},
	}
	for _, s := range steps {
		if r := a.Do(t, "PUT", s.path, s.body, auth); r.Status != 200 {
			t.Fatalf("%s: %d %s", s.path, r.Status, r.Body)
		}
	}
	return tp.Account.Id, auth
}

func TestEnrolment_WizardIsResumable(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	id, auth := enrol(t, a, phone, "male", electrician)
	contact := map[string]string{"name": "Karim Uddin", "relation": "Brother", "phone": "01812345678"}
	if r := a.Do(t, "PUT", "/v1/provider/enrolment/emergency-contact", contact, auth); r.Status != 200 {
		t.Fatalf("contact: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/provider/enrolment/emergency-contact/verify", map[string]string{"code": "000000"}, auth); r.Code(t) != "OTP_INVALID" {
		t.Fatalf("wrong code: %s", r.Body)
	}
	code := a.LastCode(t, "01812345678")
	r := a.Do(t, "POST", "/v1/provider/enrolment/emergency-contact/verify", map[string]string{"code": code}, auth)
	if r.Status != 200 {
		t.Fatalf("verify: %d %s", r.Status, r.Body)
	}
	done := map[string]bool{}
	for _, s := range r.JSON(t)["steps"].([]any) {
		m := s.(map[string]any)
		done[m["step"].(string)] = m["done"].(bool)
	}
	if !done["personal"] || !done["emergency_contact"] || done["nid"] || r.JSON(t)["complete"] != false {
		t.Fatalf("steps: %v", done)
	}
	if r := a.Do(t, "GET", "/v1/provider/enrolment", nil, auth); r.Status != 200 || len(r.JSON(t)["steps"].([]any)) != 9 {
		t.Fatalf("resume: %d %s", r.Status, r.Body)
	}
	c := a.Modules.Provider.Contract
	if err := c.MarkSubmitted(ctx, id); !errors.Is(err, contract.ErrEnrolmentIncomplete) {
		t.Fatal(err)
	}
	for _, s := range []contract.EnrolmentStep{contract.StepNID, contract.StepSelfie, contract.StepPoliceClearance} {
		if _, err := c.MarkStepDone(ctx, id, s); err != nil {
			t.Fatal(err)
		}
	}
	if err := c.MarkSubmitted(ctx, id); err != nil {
		t.Fatal(err)
	}
	st, err := c.Enrolment(ctx, id)
	if err != nil || !st.Complete || !st.Submitted {
		t.Fatalf("enrolment: %+v %v", st, err)
	}
	p, err := c.GetProvider(ctx, id)
	if err != nil || p.FullName != "Rahim Uddin" || p.EmergencyContact.Phone != "+8801812345678" || p.HomeBase.Lat != 23.7937 || p.DateOfBirth.Year() != 1990 {
		t.Fatalf("provider: %+v %v", p, err)
	}
	if _, err := c.GetProvider(ctx, uuid.New()); !errors.Is(err, contract.ErrProviderNotFound) {
		t.Fatal(err)
	}
	if st, err := c.Enrolment(ctx, uuid.New()); err != nil || st.Complete {
		t.Fatal("unknown provider enrolment")
	}
}

func TestEnrolment_Validation(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	auth := testkit.Bearer(a.SignIn(t, phone, "partner").AccessToken)
	young := personal("male")
	young["dateOfBirth"] = "2015-01-01"
	cases := []struct {
		path string
		body any
		code string
	}{
		{"/v1/provider/enrolment/personal", young, "PROVIDER_TOO_YOUNG"},
		{"/v1/provider/enrolment/personal", map[string]any{"fullName": "Rahim", "dateOfBirth": "1990-01-01", "gender": "male", "presentAddress": "     ", "permanentAddress": "Cumilla"}, "VALIDATION_FAILED"},
		{"/v1/provider/enrolment/services", map[string]any{"serviceIds": []uuid.UUID{uuid.New()}, "experienceYears": 1}, "SERVICE_UNAVAILABLE"},
		{"/v1/provider/enrolment/area", map[string]any{"homeBase": map[string]float64{"lat": 51.5, "lng": 0}, "workingRadiusM": 5000}, "VALIDATION_FAILED"},
		{"/v1/provider/enrolment/emergency-contact", map[string]string{"name": "Me", "relation": "Self", "phone": phone}, "VALIDATION_FAILED"},
		{"/v1/provider/enrolment/code-of-conduct", map[string]any{"version": "2026-10", "accepted": false}, "VALIDATION_FAILED"},
	}
	for _, c := range cases {
		if r := a.Do(t, "PUT", c.path, c.body, auth); r.Code(t) != c.code {
			t.Errorf("%s: %d %s", c.path, r.Status, r.Body)
		}
	}
	if r := a.Do(t, "POST", "/v1/provider/enrolment/emergency-contact/verify", map[string]string{"code": "123456"}, auth); r.Code(t) != "EMERGENCY_CONTACT_MISSING" {
		t.Fatalf("verify without contact: %s", r.Body)
	}
	contact := map[string]string{"name": "Karim Uddin", "relation": "Brother", "phone": "01812345678"}
	a.Do(t, "PUT", "/v1/provider/enrolment/emergency-contact", contact, auth)
	if r := a.Do(t, "PUT", "/v1/provider/enrolment/emergency-contact", contact, auth); r.Code(t) != "OTP_RATE_LIMITED" {
		t.Fatalf("second code at once: %d %s", r.Status, r.Body)
	}
}

func TestProfile_PhotoAndLanguage(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	id, auth := enrol(t, a, phone, "male", electrician)
	ctx := context.Background()
	body := []byte("jpg")
	ticket, err := a.Modules.Media.Service.CreateUpload(ctx, id, "provider", "avatar", "image/jpeg", int64(len(body)))
	if err != nil {
		t.Fatal(err)
	}
	req, _ := http.NewRequest(http.MethodPut, ticket.URL, bytes.NewReader(body))
	for k, v := range ticket.Headers {
		req.Header.Set(k, v)
	}
	if res, err := http.DefaultClient.Do(req); err != nil || res.StatusCode != 200 {
		t.Fatalf("put: %v %v", res, err)
	}
	if _, err := a.Modules.Media.Contract.ConfirmUpload(ctx, id, ticket.MediaID); err != nil {
		t.Fatal(err)
	}
	r := a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"bio": "Licensed", "language": "en", "photoMediaId": ticket.MediaID}, auth)
	j := r.JSON(t)
	if r.Status != 200 || j["photoUrl"] == nil || j["language"] != "en" || j["badge"] != "none" || len(j["services"].([]any)) != 1 || j["homeBase"] == nil {
		t.Fatalf("profile: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"language": "bn", "photoMediaId": uuid.New()}, auth); r.Code(t) != "PHOTO_INVALID" {
		t.Fatalf("unknown photo: %s", r.Body)
	}
	other := testkit.Bearer(a.SignIn(t, "01912345678", "partner").AccessToken)
	if r := a.Do(t, "GET", "/v1/provider/profile", nil, other); r.Status != 200 || r.JSON(t)["name"] != "" {
		t.Fatalf("fresh provider profile: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"language": "en"}, other); r.Status != 200 {
		t.Fatalf("fresh provider update: %d %s", r.Status, r.Body)
	}
}
