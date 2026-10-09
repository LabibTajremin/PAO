//go:build integration

package http_test

import (
	"testing"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestRating_ListsProfilePhotoAndFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	j := a.CompletedJob(t, "01712345621", "01812345621")
	p := j.Provider
	second, address := a.Customer(t, "01812345622")
	body := map[string]any{"providerId": p.ID, "serviceId": catalogapp.SeedID("service", "electrician"), "timing": "asap", "addressId": address,
		"items": []map[string]any{{"subServiceId": catalogapp.SeedID("sub-service", "fan-install"), "quantity": 1}}}
	id := a.Do(t, "POST", "/v1/customer/bookings", body, second.Auth(), testkit.Header("Idempotency-Key", "rating-second")).JSON(t)["id"].(string)
	path := "/v1/provider/jobs/" + id
	a.Do(t, "POST", path+"/accept", nil, p.Auth())
	code := a.Do(t, "GET", "/v1/customer/bookings/"+id+"/start-code", nil, second.Auth()).JSON(t)["code"].(string)
	for _, step := range []string{"on-the-way", "arrived"} {
		a.Do(t, "POST", path+"/"+step, nil, p.Auth())
	}
	a.Do(t, "POST", path+"/start", map[string]string{"code": code}, p.Auth())
	a.Do(t, "POST", path+"/complete", map[string]bool{"cashReceived": true}, p.Auth())
	a.RelayEvents(t)
	for _, c := range []struct {
		booking string
		who     testkit.Request
	}{{j.ID, j.Customer.Auth()}, {id, second.Auth()}} {
		if r := a.Do(t, "POST", "/v1/customer/bookings/"+c.booking+"/review", map[string]any{"stars": 5}, c.who); r.Status != 201 {
			t.Fatalf("review: %d %s", r.Status, r.Body)
		}
	}
	list := "/v1/customer/providers/" + p.ID.String() + "/reviews?limit=1"
	page := a.Do(t, "GET", list, nil, second.Auth()).JSON(t)
	if len(page["items"].([]any)) != 1 || page["nextCursor"] == nil {
		t.Fatalf("page 1: %v", page)
	}
	next := a.Do(t, "GET", list+"&cursor="+page["nextCursor"].(string), nil, second.Auth()).JSON(t)
	if len(next["items"].([]any)) != 1 || next["nextCursor"] != nil {
		t.Fatalf("page 2: %v", next)
	}
	photo := a.Upload(t, p.ID, "provider", "avatar")
	a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"language": "bn", "photoMediaId": photo}, p.Auth())
	if r := a.Do(t, "GET", "/v1/customer/providers/"+p.ID.String(), nil, second.Auth()); r.JSON(t)["photoUrl"] == nil {
		t.Fatalf("public photo: %s", r.Body)
	}
	pending := a.EnrolledProvider(t, "01712345623", "male", catalogapp.SeedID("service", "electrician"))
	if r := a.Do(t, "GET", "/v1/customer/providers/"+pending.ID.String(), nil, second.Auth()); r.Status != 404 {
		t.Fatalf("unverified public profile: %d", r.Status)
	}
	if r := a.Do(t, "GET", list+"&cursor=%25", nil, second.Auth()); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
	a.Infra.Pool.Close()
	for _, c := range []struct {
		path string
		who  testkit.Request
	}{{"/v1/provider/rating", p.Auth()}, {"/v1/provider/reviews", p.Auth()}, {"/v1/customer/providers/" + p.ID.String() + "/reviews", second.Auth()}} {
		if r := a.Do(t, "GET", c.path, nil, c.who); r.Status != 500 {
			t.Errorf("%s with closed pool: %d", c.path, r.Status)
		}
	}
}
