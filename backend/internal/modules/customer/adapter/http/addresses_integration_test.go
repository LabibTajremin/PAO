//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func ids(t *testing.T, r testkit.Response) (all []string, def string) {
	t.Helper()
	for _, item := range r.JSON(t)["items"].([]any) {
		m := item.(map[string]any)
		all = append(all, m["id"].(string))
		if m["isDefault"] == true {
			def = m["id"].(string)
		}
	}
	return all, def
}

func TestAddresses_DefaultsLimitAndOwnership(t *testing.T) {
	a := testkit.NewAPI(t)
	tp := a.SignIn(t, phone, "customer")
	auth := testkit.Bearer(tp.AccessToken)
	a.Do(t, "PUT", "/v1/customer/profile", profile, auth)
	first := a.Do(t, "POST", "/v1/customer/addresses", address("home", false), auth).JSON(t)
	if first["isDefault"] != true || first["location"].(map[string]any)["lat"] != 23.7937 {
		t.Fatalf("first address: %v", first)
	}
	second := a.Do(t, "POST", "/v1/customer/addresses", address("office", true), auth).JSON(t)
	all, def := ids(t, a.Do(t, "GET", "/v1/customer/addresses", nil, auth))
	if len(all) != 2 || def != second["id"] {
		t.Fatalf("default switch: %v %s", all, def)
	}
	path := "/v1/customer/addresses/" + first["id"].(string)
	edit := address("other", true)
	edit["line1"] = "House 14, Road 7"
	if r := a.Do(t, "PUT", path, edit, auth); r.Status != 200 || r.JSON(t)["isDefault"] != true || r.JSON(t)["line1"] != "House 14, Road 7" {
		t.Fatalf("edit to default: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/customer/addresses/"+second["id"].(string)+"/default", nil, auth); r.JSON(t)["isDefault"] != true {
		t.Fatalf("set default: %s", r.Body)
	}
	if r := a.Do(t, "PUT", path, address("home", false), auth); r.JSON(t)["isDefault"] != false {
		t.Fatalf("plain edit: %s", r.Body)
	}
	if r := a.Do(t, "DELETE", path, nil, auth); r.Status != 204 {
		t.Fatalf("delete non-default: %d", r.Status)
	}
	third := a.Do(t, "POST", "/v1/customer/addresses", address("home", false), auth).JSON(t)
	a.Do(t, "DELETE", "/v1/customer/addresses/"+second["id"].(string), nil, auth)
	if _, def := ids(t, a.Do(t, "GET", "/v1/customer/addresses", nil, auth)); def != third["id"] {
		t.Fatalf("newest not promoted: %s", def)
	}
	for range 9 {
		a.Do(t, "POST", "/v1/customer/addresses", address("other", false), auth)
	}
	if r := a.Do(t, "POST", "/v1/customer/addresses", address("other", false), auth); r.Code(t) != "ADDRESS_LIMIT" {
		t.Fatalf("eleventh address: %s", r.Body)
	}
	got, err := a.Modules.Customer.Contract.GetAddress(context.Background(), tp.Account.Id, uuid.MustParse(third["id"].(string)))
	if err != nil || got.Location.Lng != 90.4066 || got.Area != "Banani" {
		t.Fatalf("contract address: %+v %v", got, err)
	}
	stranger := testkit.Bearer(a.Token(t, uuid.New(), "customer"))
	thirdPath := "/v1/customer/addresses/" + third["id"].(string)
	a.Do(t, "PUT", "/v1/customer/profile", profile, stranger)
	for _, c := range []struct {
		method, path string
		body         any
	}{{"PUT", thirdPath, address("home", false)}, {"DELETE", thirdPath, nil}, {"POST", thirdPath + "/default", nil}} {
		if r := a.Do(t, c.method, c.path, c.body, stranger); r.Status != 404 {
			t.Errorf("stranger %s: %d", c.method, r.Status)
		}
	}
}

func TestAddresses_ValidationAndServiceArea(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	super := a.Admin(t, "super_admin")
	auth := testkit.Bearer(a.SignIn(t, phone, "customer").AccessToken)
	a.Do(t, "PUT", "/v1/customer/profile", profile, auth)
	abroad := address("home", false)
	abroad["location"] = map[string]float64{"lat": 51.5, "lng": -0.12}
	if r := a.Do(t, "POST", "/v1/customer/addresses", abroad, auth); r.Code(t) != "LOCATION_OUTSIDE_BANGLADESH" {
		t.Fatalf("abroad: %s", r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/customer/addresses/"+uuid.NewString(), address("home", false), auth); r.Status != 404 {
		t.Fatalf("unknown: %d", r.Status)
	}
	noLines := map[string]any{"label": "home", "line1": "Road 5", "location": map[string]float64{"lat": 23.8, "lng": 90.4}}
	if r := a.Do(t, "POST", "/v1/customer/addresses", noLines, auth); r.Status != 201 || r.JSON(t)["line2"] != "" {
		t.Fatalf("optional lines: %d %s", r.Status, r.Body)
	}
	area := `{"type":"Polygon","coordinates":[[[90.3,23.7],[90.5,23.7],[90.5,23.9],[90.3,23.9],[90.3,23.7]]]}`
	if r := a.Do(t, "PUT", "/v1/admin/settings/service_area.geojson", map[string]string{"value": area}, testkit.Bearer(super.AccessToken)); r.Status != 200 {
		t.Fatalf("set area: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/service-area?lat=23.8&lng=90.4", nil, auth); r.JSON(t)["covered"] != true {
		t.Fatalf("inside: %s", r.Body)
	}
	if ok, _ := a.Modules.Customer.Contract.IsInServiceArea(ctx, geo.Point{Lat: 22.3, Lng: 91.8}); ok {
		t.Fatal("Chattogram covered by a Dhaka area")
	}
}
