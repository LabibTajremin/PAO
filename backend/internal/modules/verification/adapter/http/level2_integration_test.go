//go:build integration

package http_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestLevel2_FailCoolOffPass(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	p := a.VerifiedProvider(t, "01712345678", "male", electrician)
	auth := testkit.Bearer(a.Admin(t, "verifier").AccessToken)
	when := a.Clock.Now().Add(48 * time.Hour).UTC().Format(time.RFC3339)
	body := map[string]any{"providerId": p.ID, "serviceId": electrician, "scheduledAt": when, "location": "PAO office, Gulshan 1"}
	r := a.Do(t, "POST", "/v1/admin/level2-sessions", body, auth)
	if r.Status != 201 {
		t.Fatalf("schedule: %d %s", r.Status, r.Body)
	}
	first := r.JSON(t)["id"].(string)
	fail := map[string]any{"result": "fail", "checklist": []map[string]any{{"item": "Safe wiring", "passed": false}}, "notes": "Unsafe joints",
		"visitLocation": map[string]float64{"lat": 23.79, "lng": 90.41}, "photoMediaIds": []uuid.UUID{a.Upload(t, p.ID, "admin", "level2_photo")}}
	if r := a.Do(t, "POST", "/v1/admin/level2-sessions/"+first+"/result", fail, auth); r.Status != 200 || r.JSON(t)["result"] != "fail" {
		t.Fatalf("fail: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/admin/level2-sessions/"+first+"/result", fail, auth); r.Code(t) != "SESSION_CLOSED" {
		t.Fatalf("second result: %s", r.Body)
	}
	if r := a.Do(t, "POST", "/v1/admin/level2-sessions", body, auth); r.Code(t) != "LEVEL2_COOLING_OFF" {
		t.Fatalf("cooling-off: %s", r.Body)
	}
	if st := a.Do(t, "GET", "/v1/provider/verification", nil, p.Auth()).JSON(t); st["level2"].(map[string]any)["retryAfter"] == nil {
		t.Fatalf("retry after: %v", st)
	}
	a.Clock.Advance(15 * 24 * time.Hour)
	auth = testkit.Bearer(a.Admin(t, "verifier").AccessToken)
	p.Token = a.Token(t, p.ID, "provider")
	body["scheduledAt"] = a.Clock.Now().Add(time.Hour).UTC().Format(time.RFC3339)
	r = a.Do(t, "POST", "/v1/admin/level2-sessions", body, auth)
	if r.Status != 201 {
		t.Fatalf("reschedule: %d %s", r.Status, r.Body)
	}
	second := r.JSON(t)["id"].(string)
	if st := a.Do(t, "GET", "/v1/provider/verification", nil, p.Auth()).JSON(t); st["level2"].(map[string]any)["nextSession"] == nil {
		t.Fatalf("next session: %v", st)
	}
	pass := map[string]any{"result": "pass", "checklist": []map[string]any{{"item": "Safe wiring", "passed": true}}}
	if r := a.Do(t, "POST", "/v1/admin/level2-sessions/"+second+"/result", pass, auth); r.Status != 200 {
		t.Fatalf("pass: %d %s", r.Status, r.Body)
	}
	a.RelayEvents(t)
	if st := a.Do(t, "GET", "/v1/provider/verification", nil, p.Auth()).JSON(t); st["level"] != float64(2) || st["badge"] != "verified_pro" {
		t.Fatalf("level 2: %v", st)
	}
	list := a.Do(t, "GET", "/v1/admin/level2-sessions?limit=1&status=completed&providerId="+p.ID.String(), nil, auth).JSON(t)
	if len(list["items"].([]any)) != 1 || list["nextCursor"] == nil {
		t.Fatalf("sessions page 1: %v", list)
	}
	next := a.Do(t, "GET", "/v1/admin/level2-sessions?limit=1&status=completed&cursor="+list["nextCursor"].(string), nil, auth).JSON(t)
	if len(next["items"].([]any)) != 1 || next["nextCursor"] != nil {
		t.Fatalf("sessions page 2: %v", next)
	}
	if r := a.Do(t, "GET", "/v1/admin/level2-sessions/"+first, nil, auth); r.JSON(t)["notes"] != "Unsafe joints" {
		t.Fatalf("get session: %s", r.Body)
	}
	for _, path := range []string{"/v1/admin/level2-sessions/" + uuid.NewString(), "/v1/admin/level2-sessions?cursor=%25"} {
		if r := a.Do(t, "GET", path, nil, auth); r.Status != 404 && r.Status != 422 {
			t.Errorf("%s: %d", path, r.Status)
		}
	}
	stranger := map[string]any{"providerId": uuid.New(), "serviceId": electrician, "scheduledAt": body["scheduledAt"], "location": "Office"}
	if r := a.Do(t, "POST", "/v1/admin/level2-sessions", stranger, auth); r.Code(t) != "LEVEL2_NOT_ELIGIBLE" {
		t.Fatalf("unverified provider: %s", r.Body)
	}
	stranger["serviceId"] = uuid.New()
	if r := a.Do(t, "POST", "/v1/admin/level2-sessions", stranger, auth); r.Status != 422 {
		t.Fatalf("unknown service: %d", r.Status)
	}
}

func TestExpiry_RemindsThenDropsLevel(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	p := a.VerifiedProvider(t, "01712345678", "male", electrician)
	a.Do(t, "POST", "/v1/provider/presence/online", map[string]any{"location": map[string]float64{"lat": 23.79, "lng": 90.41}}, p.Auth())
	expire, remind := inproc.NewWorkers(a.Modules.Verification.Service)
	var expires time.Time
	if err := a.Infra.Pool.QueryRow(ctx, "SELECT expires_at FROM verification.items WHERE provider_id = $1 AND item_type = 'police_clearance'", p.ID).Scan(&expires); err != nil {
		t.Fatal(err)
	}
	a.Clock.Set(expires.Add(-29*24*time.Hour - 12*time.Hour))
	for range 2 {
		if err := remind.Work(ctx, nil); err != nil {
			t.Fatal(err)
		}
	}
	var reminders int
	_ = a.Infra.Pool.QueryRow(ctx, "SELECT count(*) FROM verification.outbox WHERE event_name = 'verification.DocumentExpiring'").Scan(&reminders)
	if reminders != 1 {
		t.Fatalf("30-day reminders: %d", reminders)
	}
	a.Clock.Advance(31 * 24 * time.Hour)
	if err := expire.Work(ctx, nil); err != nil {
		t.Fatal(err)
	}
	a.RelayEvents(t)
	p.Token = a.Token(t, p.ID, "provider")
	st := a.Do(t, "GET", "/v1/provider/verification", nil, p.Auth()).JSON(t)
	if st["level"] != float64(0) || st["canReceiveBookings"] != false {
		t.Fatalf("after expiry: %v", st)
	}
	if ok, _ := a.Modules.Provider.Contract.IsAvailable(ctx, p.ID); ok {
		t.Fatal("expired provider still online")
	}
	a.Modules.Verification.RegisterJobs(jobs.NewRegistry())
}
