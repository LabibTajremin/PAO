//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

var near = map[string]any{"location": map[string]float64{"lat": 23.7940, "lng": 90.4070}}

func online(t *testing.T, a *testkit.API, p, gender string, level int, services ...uuid.UUID) (uuid.UUID, testkit.Request) {
	t.Helper()
	id, auth := enrol(t, a, p, gender, services...)
	a.Deliver(t, verification.ProviderLevelChanged{ProviderID: id, From: 0, To: level})
	if r := a.Do(t, "POST", "/v1/provider/presence/online", near, auth); r.Status != 200 || r.JSON(t)["online"] != true {
		t.Fatalf("online: %d %s", r.Status, r.Body)
	}
	return id, auth
}

func TestPresence_OnlineHeartbeatOffline(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	_, unverified := enrol(t, a, "01912345678", "male", electrician)
	if r := a.Do(t, "POST", "/v1/provider/presence/online", near, unverified); r.Code(t) != "NOT_VERIFIED" {
		t.Fatalf("unverified online: %s", r.Body)
	}
	id, auth := online(t, a, phone, "male", 1, electrician)
	if r := a.Do(t, "POST", "/v1/provider/presence/heartbeat", near, auth); r.Status != 200 {
		t.Fatalf("heartbeat: %d", r.Status)
	}
	if r := a.Do(t, "GET", "/v1/provider/profile", nil, auth); r.JSON(t)["online"] != true || r.JSON(t)["badge"] != "verified" {
		t.Fatalf("profile: %s", r.Body)
	}
	if ok, _ := a.Modules.Provider.Contract.IsAvailable(ctx, id); !ok {
		t.Fatal("not available")
	}
	if r := a.Do(t, "POST", "/v1/provider/presence/offline", nil, auth); r.JSON(t)["online"] != false {
		t.Fatalf("offline: %s", r.Body)
	}
	if r := a.Do(t, "POST", "/v1/provider/presence/heartbeat", near, auth); r.Code(t) != "OFFLINE" {
		t.Fatalf("heartbeat offline: %s", r.Body)
	}
	a.Do(t, "POST", "/v1/provider/presence/online", near, auth)
	a.Infra.Redis.Del(ctx, a.Infra.Keys.Key("presence", "hb", id.String()))
	if err := inproc.NewReapWorker(a.Modules.Provider.Service).Work(ctx, nil); err != nil {
		t.Fatal(err)
	}
	if ok, _ := a.Modules.Provider.Contract.IsAvailable(ctx, id); ok {
		t.Fatal("lost heartbeat kept online")
	}
	a.Do(t, "POST", "/v1/provider/presence/online", near, auth)
	if err := a.Modules.Provider.Contract.ForceOffline(ctx, id); err != nil {
		t.Fatal(err)
	}
	if r := a.Do(t, "POST", "/v1/provider/presence/heartbeat", near, auth); r.Code(t) != "OFFLINE" {
		t.Fatalf("forced offline: %s", r.Body)
	}
	a.Do(t, "POST", "/v1/provider/presence/online", near, auth)
	a.Do(t, "PUT", "/v1/provider/enrolment/services", map[string]any{"serviceIds": []uuid.UUID{electrician}, "experienceYears": 9}, auth)
	if ok, _ := a.Modules.Provider.Contract.IsAvailable(ctx, id); ok {
		t.Fatal("changing services kept the provider online")
	}
	stranger := testkit.Bearer(a.Token(t, uuid.New(), "provider"))
	for _, path := range []string{"/v1/provider/presence/online", "/v1/provider/presence/heartbeat"} {
		if r := a.Do(t, "POST", path, near, stranger); r.Status != 404 {
			t.Errorf("%s unknown provider: %d", path, r.Status)
		}
	}
	if r := a.Do(t, "POST", "/v1/provider/presence/offline", nil, stranger); r.Status != 404 {
		t.Fatalf("offline unknown: %d", r.Status)
	}
	a.Modules.RegisterJobs(jobs.NewRegistry())
}

func TestFindNearby_RanksAndHonoursWomenOnly(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	man, _ := online(t, a, "01712345601", "male", 1, electrician, homeSalon)
	woman, _ := online(t, a, "01712345602", "female", 1, homeSalon)
	pro, _ := online(t, a, "01712345603", "female", 2, electrician, homeSalon)
	dhaka := geo.Point{Lat: 23.7937, Lng: 90.4066}
	got, err := a.Modules.Provider.Contract.FindNearby(ctx, contract.NearbyQuery{ServiceID: homeSalon, Point: dhaka, RadiusM: 5000, Sort: contract.SortDistance, Limit: 10})
	if err != nil || len(got) != 2 || got[0].ProviderID != pro || got[1].ProviderID != woman || got[0].Name != "Rahim Uddin" {
		t.Fatalf("salon: %+v %v", got, err)
	}
	got, _ = a.Modules.Provider.Contract.FindNearby(ctx, contract.NearbyQuery{ServiceID: electrician, Point: dhaka, RadiusM: 5000, Sort: contract.SortRating})
	if len(got) != 2 || got[0].ProviderID != pro || got[1].ProviderID != man {
		t.Fatalf("electrician: %+v", got)
	}
	if _, err := a.Infra.Pool.Exec(ctx, "UPDATE catalog.services SET requires_level_2 = true WHERE id = $1", homeSalon); err != nil {
		t.Fatal(err)
	}
	got, _ = a.Modules.Provider.Contract.FindNearby(ctx, contract.NearbyQuery{ServiceID: homeSalon, Point: dhaka, RadiusM: 5000})
	if len(got) != 1 || got[0].ProviderID != pro {
		t.Fatalf("level 2 service: %+v", got)
	}
	far := geo.Point{Lat: 22.35, Lng: 91.78}
	if got, _ := a.Modules.Provider.Contract.FindNearby(ctx, contract.NearbyQuery{ServiceID: electrician, Point: far, RadiusM: 5000}); len(got) != 0 {
		t.Fatalf("Chattogram: %+v", got)
	}
	if _, err := a.Modules.Provider.Contract.FindNearby(ctx, contract.NearbyQuery{ServiceID: uuid.New(), Point: dhaka, RadiusM: 5000}); err == nil {
		t.Fatal("unknown service searched")
	}
}
