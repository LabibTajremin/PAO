//go:build integration

package http_test

import (
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestMonitor_FiltersAndDetail(t *testing.T) {
	a := testkit.NewAPI(t)
	done := a.CompletedJob(t, "01712345691", "01812345691")
	open := a.RequestedJob(t, "01712345692", "01812345692")
	auth := testkit.Bearer(a.Admin(t, "support_agent").AccessToken)
	today := a.Clock.Now().In(clock.Dhaka)
	day, tomorrow := today.Format("2006-01-02"), today.AddDate(0, 0, 1).Format("2006-01-02")
	electrician := catalogapp.SeedID("service", "electrician").String()
	for query, want := range map[string]int{
		"": 2, "?status=completed": 1, "?serviceId=" + electrician: 2, "?serviceId=" + uuid.NewString(): 0, "?area=banani": 2,
		"?area=Gulshan": 0, "?from=" + day + "&to=" + day: 2, "?from=" + tomorrow: 0, "?to=" + today.AddDate(0, 0, -1).Format("2006-01-02"): 0,
	} {
		r := a.Do(t, "GET", "/v1/admin/bookings"+query, nil, auth)
		if r.Status != http.StatusOK || len(r.JSON(t)["items"].([]any)) != want {
			t.Errorf("bookings%s: %d %s", query, r.Status, r.Body)
		}
	}
	first := a.Do(t, "GET", "/v1/admin/bookings?limit=1", nil, auth).JSON(t)
	row := first["items"].([]any)[0].(map[string]any)
	if row["id"] != open.ID || !strings.Contains(row["counterpartName"].(string), " → ") {
		t.Fatalf("first page: %v", first)
	}
	rest := a.Do(t, "GET", "/v1/admin/bookings?limit=1&cursor="+first["nextCursor"].(string), nil, auth).JSON(t)
	if items := rest["items"].([]any); len(items) != 1 || items[0].(map[string]any)["id"] != done.ID || rest["nextCursor"] != nil {
		t.Fatalf("second page: %v", rest)
	}
	d := a.Do(t, "GET", "/v1/admin/bookings/"+open.ID, nil, auth).JSON(t)
	if d["customer"].(map[string]any)["phone"] == nil || d["provider"].(map[string]any)["phone"] == nil || len(d["timeline"].([]any)) == 0 {
		t.Fatalf("detail: %v", d)
	}
	if r := a.Do(t, "GET", "/v1/admin/bookings/"+uuid.NewString(), nil, auth); r.Status != 404 {
		t.Fatalf("unknown booking: %d", r.Status)
	}
	if r := a.Do(t, "GET", "/v1/admin/bookings?cursor=%25", nil, auth); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
	a.Infra.Pool.Close()
	for _, p := range []string{"/v1/admin/bookings", "/v1/admin/bookings/" + open.ID} {
		if r := a.Do(t, "GET", p, nil, auth); r.Status != 500 {
			t.Errorf("%s closed pool: %d", p, r.Status)
		}
	}
}
