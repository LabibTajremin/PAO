//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

var electrician = catalogapp.SeedID("service", "electrician")

func TestVerification_FullEnrolmentToLevelOne(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	p := a.EnrolledProvider(t, "01712345678", "male", electrician)
	if r := a.Do(t, "GET", "/v1/me/permissions", nil, p.Auth()); r.Status != 200 {
		t.Fatalf("permissions: %d", r.Status)
	}
	verifier := a.Admin(t, "verifier")
	auth := testkit.Bearer(verifier.AccessToken)
	q := a.Do(t, "GET", "/v1/admin/verifications?serviceId="+electrician.String()+"&itemType=nid", nil, auth)
	items := q.JSON(t)["items"].([]any)
	if q.Status != 200 || len(items) != 1 || items[0].(map[string]any)["name"] != "Rahim Uddin" || len(items[0].(map[string]any)["pendingItems"].([]any)) != 7 {
		t.Fatalf("queue: %d %s", q.Status, q.Body)
	}
	if r := a.Do(t, "GET", "/v1/admin/verifications?itemType=skill_proof", nil, auth); len(r.JSON(t)["items"].([]any)) != 0 {
		t.Fatalf("skill proof filter: %s", r.Body)
	}
	path := "/v1/admin/verifications/" + p.ID.String()
	r := a.Do(t, "GET", path, nil, auth)
	rv := r.JSON(t)
	if r.Status != 200 || rv["profile"].(map[string]any)["nidNumber"] != "1712345678" || rv["faceMatch"] != "manual_review" {
		t.Fatalf("review: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", path+"/items/selfie/reject", map[string]string{"reason": "Face not visible"}, auth); r.Status != 200 {
		t.Fatalf("reject: %d %s", r.Status, r.Body)
	}
	status := a.Do(t, "GET", "/v1/provider/verification", nil, p.Auth()).JSON(t)
	if status["level"] != float64(0) || status["canReceiveBookings"] != false {
		t.Fatalf("status: %v", status)
	}
	if r := a.Do(t, "POST", path+"/items/selfie/approve", nil, auth); r.Code(t) != "ITEM_NOT_PENDING" {
		t.Fatalf("approve rejected: %s", r.Body)
	}
	a.Do(t, "PUT", "/v1/provider/enrolment/selfie", map[string]any{"mediaId": a.Upload(t, p.ID, "provider", "selfie")}, p.Auth())
	for _, item := range []string{"nid", "selfie", "police_clearance", "address", "emergency_contact", "service_area", "code_of_conduct"} {
		if r := a.Do(t, "POST", path+"/items/"+item+"/approve", nil, auth); r.Status != 200 {
			t.Fatalf("approve %s: %d %s", item, r.Status, r.Body)
		}
	}
	a.RelayEvents(t)
	status = a.Do(t, "GET", "/v1/provider/verification", nil, p.Auth()).JSON(t)
	if status["level"] != float64(1) || status["badge"] != "verified" || status["canReceiveBookings"] != true || status["level2"].(map[string]any)["eligible"] != true {
		t.Fatalf("level 1 status: %v", status)
	}
	if r := a.Do(t, "POST", "/v1/provider/presence/online", map[string]any{"location": map[string]float64{"lat": 23.79, "lng": 90.41}}, p.Auth()); r.Status != 200 {
		t.Fatalf("online after verification: %d %s", r.Status, r.Body)
	}
	if ok, err := a.Modules.Verification.Contract.CanReceiveBookings(ctx, p.ID, electrician); !ok || err != nil {
		t.Fatalf("can receive: %v %v", ok, err)
	}
	if lvl, err := a.Modules.Verification.Contract.GetLevel(ctx, uuid.New()); lvl != 0 || err != nil {
		t.Fatal("unknown provider level")
	}
	if _, err := a.Infra.Pool.Exec(ctx, "UPDATE catalog.services SET requires_level_2 = true WHERE id = $1", electrician); err != nil {
		t.Fatal(err)
	}
	if ok, _ := a.Modules.Verification.Contract.CanReceiveBookings(ctx, p.ID, electrician); ok {
		t.Fatal("level 1 provider may take a Level 2 service")
	}
	levels, err := a.Modules.Verification.Contract.GetLevels(ctx, []uuid.UUID{p.ID, uuid.New()})
	if err != nil || levels[p.ID] != 1 || len(levels) != 1 {
		t.Fatalf("levels: %v %v", levels, err)
	}
	entries, err := a.Modules.Audit.Contract.ListForSubject(ctx, "provider", p.ID.String(), 50)
	if err != nil || len(entries) != 9 {
		t.Fatalf("audit entries: %d %v", len(entries), err)
	}
	doc := rv["items"].([]any)[0].(map[string]any)["documents"].([]any)[0].(map[string]any)["mediaId"].(string)
	if r := a.Do(t, "GET", "/v1/admin/documents/"+doc+"/view-url", nil, auth); r.Status != 200 {
		t.Fatalf("document view: %d", r.Status)
	}
}
