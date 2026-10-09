//go:build integration

package http_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestBan_BlocksNIDAndBookings(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	p := a.VerifiedProvider(t, "01712345678", "male", electrician)
	super := a.Admin(t, "super_admin")
	_, err := a.Modules.Identity.Contract.SetAccountStatus(ctx, identity.SetAccountStatusInput{AccountID: p.ID, Status: identity.StatusBanned, Reason: "fraud", ActorID: super.ID})
	if err != nil {
		t.Fatal(err)
	}
	a.RelayEvents(t)
	if ok, _ := a.Modules.Verification.Contract.CanReceiveBookings(ctx, p.ID, uuid.Nil); ok {
		t.Fatal("banned provider can receive bookings")
	}
	other := a.SignIn(t, "01812345678", "partner")
	nid := map[string]any{"nidNumber": "1712345678", "frontMediaId": a.Upload(t, other.Account.Id, "provider", "nid_front"),
		"backMediaId": a.Upload(t, other.Account.Id, "provider", "nid_back")}
	if r := a.Do(t, "PUT", "/v1/provider/enrolment/nid", nid, testkit.Bearer(other.AccessToken)); r.Code(t) != "NID_BLOCKED" {
		t.Fatalf("banned NID: %s", r.Body)
	}
}

func TestDocuments_Validation(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	tp := a.SignIn(t, "01712345678", "partner")
	auth := testkit.Bearer(tp.AccessToken)
	selfie := a.Upload(t, tp.Account.Id, "provider", "selfie")
	foreign := a.Upload(t, uuid.New(), "provider", "selfie")
	old := a.Clock.Now().AddDate(-2, 0, 0).Format("2006-01-02")
	cases := []struct {
		path string
		body any
		code string
	}{
		{"/v1/provider/enrolment/selfie", map[string]any{"mediaId": foreign}, "DOCUMENT_INVALID"},
		{"/v1/provider/enrolment/selfie", map[string]any{"mediaId": uuid.New()}, "DOCUMENT_INVALID"},
		{"/v1/provider/enrolment/police-clearance", map[string]any{"mediaId": selfie, "issueDate": a.Clock.Now().Format("2006-01-02")}, "DOCUMENT_INVALID"},
		{"/v1/provider/enrolment/police-clearance", map[string]any{"mediaId": selfie, "issueDate": old}, "CLEARANCE_TOO_OLD"},
		{"/v1/provider/enrolment/skill-proof", map[string]any{"mediaIds": []uuid.UUID{}}, "VALIDATION_FAILED"},
	}
	for _, c := range cases {
		if r := a.Do(t, "PUT", c.path, c.body, auth); r.Code(t) != c.code {
			t.Errorf("%s: %d %s", c.path, r.Status, r.Body)
		}
	}
	proof := a.Upload(t, tp.Account.Id, "provider", "skill_proof")
	if r := a.Do(t, "PUT", "/v1/provider/enrolment/skill-proof", map[string]any{"mediaIds": []uuid.UUID{proof}}, auth); r.Status != 200 {
		t.Fatalf("skill proof: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/provider/enrolment/submit", nil, auth); r.Code(t) != "ENROLMENT_INCOMPLETE" {
		t.Fatalf("early submit: %s", r.Body)
	}
	verifier := testkit.Bearer(a.Admin(t, "verifier").AccessToken)
	if r := a.Do(t, "GET", "/v1/admin/verifications/"+uuid.NewString(), nil, verifier); r.Status != 404 {
		t.Fatalf("unknown review: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/admin/verifications/"+tp.Account.Id.String()+"/items/nid/reject", map[string]string{"reason": "   "}, verifier); r.Status != 422 {
		t.Fatalf("blank reason: %d", r.Status)
	}
	if r := a.Do(t, "GET", "/v1/admin/verifications?cursor=%25", nil, verifier); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
}

func TestQueue_PagingAndFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	first := a.EnrolledProvider(t, "01712345601", "male", electrician)
	a.Clock.Advance(time.Minute)
	a.EnrolledProvider(t, "01712345602", "male", electrician)
	auth := testkit.Bearer(a.Admin(t, "verifier").AccessToken)
	page := a.Do(t, "GET", "/v1/admin/verifications?limit=1", nil, auth).JSON(t)
	if len(page["items"].([]any)) != 1 || page["items"].([]any)[0].(map[string]any)["providerId"] != first.ID.String() || page["nextCursor"] == nil {
		t.Fatalf("page 1: %v", page)
	}
	next := a.Do(t, "GET", "/v1/admin/verifications?limit=1&cursor="+page["nextCursor"].(string), nil, auth).JSON(t)
	if len(next["items"].([]any)) != 1 || next["nextCursor"] != nil {
		t.Fatalf("page 2: %v", next)
	}
	for _, name := range []string{"provider.EnrolmentStepSaved", "identity.AccountStatusChanged"} {
		if err := a.Bus.Dispatch(ctx, eventbus.Envelope{ID: uuid.New(), Name: name, Payload: []byte("{")}); err == nil {
			t.Errorf("%s accepted a broken payload", name)
		}
	}
	a.Deliver(t, provider.EnrolmentStepSaved{ProviderID: first.ID, Step: provider.StepNID})
	a.Do(t, "GET", "/v1/admin/level2-sessions", nil, auth)
	a.Infra.Pool.Close()
	for _, path := range []string{"/v1/admin/verifications", "/v1/admin/level2-sessions", "/v1/provider/verification"} {
		tok := auth
		if path == "/v1/provider/verification" {
			tok = first.Auth()
		}
		if r := a.Do(t, "GET", path, nil, tok); r.Status != 500 {
			t.Errorf("%s with closed pool: %d", path, r.Status)
		}
	}
	if _, err := a.Modules.Verification.Contract.GetLevel(ctx, first.ID); err == nil {
		t.Fatal("level without a database")
	}
}
