//go:build integration

package http_test

import (
	"context"
	"fmt"
	"net/http"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestCatalog_BrowseSearchAndDetail(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	customer := testkit.Bearer(a.SignIn(t, "01712345678", "customer").AccessToken)
	r := a.Do(t, "GET", "/v1/customer/catalog", nil, customer)
	var tree api.CatalogTree
	r.Decode(t, &tree)
	if r.Status != 200 || len(tree.Categories) != 5 {
		t.Fatalf("catalog: %d %s", r.Status, r.Body)
	}
	for q, want := range map[string]string{"fan": "fan-install", "ফ্যান": "fan-install", "plumbr": "plumber", "স্যালন": "home-salon"} {
		r := a.Do(t, "GET", "/v1/customer/catalog/search?q="+urlEncode(q), nil, customer)
		var res api.CatalogSearchResults
		r.Decode(t, &res)
		if r.Status != 200 || !contains(res, want) {
			t.Errorf("search %q: %s", q, r.Body)
		}
	}
	electrician := catalogapp.SeedID("service", "electrician")
	r = a.Do(t, "GET", "/v1/customer/services/"+electrician.String(), nil, customer)
	if r.Status != 200 || len(r.JSON(t)["subServices"].([]any)) != 5 {
		t.Fatalf("service: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/services/"+uuid.NewString(), nil, customer); r.Status != 404 {
		t.Fatalf("unknown service: %d", r.Status)
	}
	provider := testkit.Bearer(a.SignIn(t, "01812345678", "partner").AccessToken)
	if r := a.Do(t, "GET", "/v1/provider/catalog", nil, provider); r.Status != 200 {
		t.Fatalf("provider catalog: %d", r.Status)
	}
}

func contains(res api.CatalogSearchResults, key string) bool {
	for _, s := range res.Services {
		if s.Id == catalogapp.SeedID("service", key) {
			return true
		}
	}
	for _, s := range res.SubServices {
		if s.Id == catalogapp.SeedID("sub-service", key) {
			return true
		}
	}
	return false
}

func urlEncode(s string) string {
	out := ""
	for _, b := range []byte(s) {
		out += fmt.Sprintf("%%%02X", b)
	}
	return out
}

func TestCatalog_AdminEditsAndPriceVersions(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	admin := testkit.Bearer(a.Admin(t, "catalog_manager").AccessToken)
	name := map[string]string{"en": "Cleaning", "bn": "পরিষ্কার"}
	r := a.Do(t, "POST", "/v1/admin/catalog/categories", map[string]any{"name": name, "iconKey": "broom", "published": true}, admin)
	if r.Status != 201 {
		t.Fatalf("category: %d %s", r.Status, r.Body)
	}
	catID := r.JSON(t)["id"].(string)
	svcBody := map[string]any{"categoryId": catID, "name": name, "iconKey": "broom", "serviceModel": "on_demand", "requiredLevel": 1, "searchRadiusM": 5000, "published": true,
		"level2Checklist": []any{name}}
	r = a.Do(t, "POST", "/v1/admin/catalog/services", svcBody, admin)
	if r.Status != 201 {
		t.Fatalf("service: %d %s", r.Status, r.Body)
	}
	svcID := r.JSON(t)["id"].(string)
	sub := map[string]any{"serviceId": svcID, "name": name, "unit": "job", "initialPrice": 100000, "published": true,
		"description": name, "inclusions": []any{name}, "exclusions": []any{}}
	r = a.Do(t, "POST", "/v1/admin/catalog/sub-services", sub, admin)
	if r.Status != 201 {
		t.Fatalf("sub-service: %d %s", r.Status, r.Body)
	}
	subID := uuid.MustParse(r.JSON(t)["id"].(string))
	before, err := a.Modules.Catalog.Contract.GetPriceSnapshot(context.Background(), subID)
	if err != nil || before.AmountPaisa != 100000 {
		t.Fatalf("snapshot: %+v %v", before, err)
	}
	if r := a.Do(t, "POST", "/v1/admin/catalog/sub-services/"+subID.String()+"/prices", map[string]int{"amount": 120000}, admin); r.Status != 201 {
		t.Fatalf("price: %d %s", r.Status, r.Body)
	}
	after, _ := a.Modules.Catalog.Contract.GetPriceSnapshot(context.Background(), subID)
	if after.AmountPaisa != 120000 || after.PriceVersionID == before.PriceVersionID {
		t.Fatal("price not versioned")
	}
	r = a.Do(t, "GET", "/v1/admin/catalog/sub-services/"+subID.String()+"/prices", nil, admin)
	if r.Status != 200 || len(r.JSON(t)["items"].([]any)) != 2 {
		t.Fatalf("history: %s", r.Body)
	}
	updates := []struct {
		path string
		body any
	}{
		{"/v1/admin/catalog/categories/" + catID, map[string]any{"name": name, "iconKey": "broom", "published": false}},
		{"/v1/admin/catalog/services/" + svcID, svcBody},
		{"/v1/admin/catalog/sub-services/" + subID.String(), sub},
	}
	for _, u := range updates {
		if r := a.Do(t, "PUT", u.path, u.body, admin); r.Status != 200 {
			t.Errorf("PUT %s: %d %s", u.path, r.Status, r.Body)
		}
	}
	r = a.Do(t, "GET", "/v1/admin/catalog", nil, admin)
	var tree api.CatalogTree
	r.Decode(t, &tree)
	if r.Status != 200 || len(tree.Categories) != 6 {
		t.Fatalf("admin tree: %d", len(tree.Categories))
	}
}

func TestCatalog_AdminRefusals(t *testing.T) {
	a := testkit.NewAPI(t)
	admin := testkit.Bearer(a.Admin(t, "catalog_manager").AccessToken)
	name := map[string]string{"en": "X", "bn": "Y"}
	missing := uuid.NewString()
	cases := []struct {
		method, path string
		body         any
		status       int
	}{
		{"PUT", "/v1/admin/catalog/categories/" + missing, map[string]any{"name": name, "iconKey": "x", "sortOrder": 3}, 404},
		{"PUT", "/v1/admin/catalog/services/" + missing, map[string]any{"categoryId": missing, "name": name, "iconKey": "x", "serviceModel": "on_demand", "requiredLevel": 1, "searchRadiusM": 5000}, 404},
		{"POST", "/v1/admin/catalog/services", map[string]any{"categoryId": missing, "name": name, "iconKey": "x", "serviceModel": "on_demand", "requiredLevel": 1, "searchRadiusM": 5000}, 404},
		{"POST", "/v1/admin/catalog/services", map[string]any{"categoryId": missing, "name": name, "iconKey": "x", "serviceModel": "on_demand", "requiredLevel": 1, "searchRadiusM": 5000, "requiresLevel2": true}, 422},
		{"POST", "/v1/admin/catalog/sub-services", map[string]any{"serviceId": missing, "name": name, "unit": "job"}, 422},
		{"POST", "/v1/admin/catalog/sub-services", map[string]any{"serviceId": missing, "name": name, "unit": "job", "initialPrice": 1}, 404},
		{"PUT", "/v1/admin/catalog/sub-services/" + missing, map[string]any{"serviceId": missing, "name": name, "unit": "job"}, 404},
		{"POST", "/v1/admin/catalog/sub-services/" + missing + "/prices", map[string]int{"amount": 1}, 404},
		{"GET", "/v1/admin/catalog/sub-services/" + missing + "/prices", nil, 404},
	}
	for _, c := range cases {
		if r := a.Do(t, c.method, c.path, c.body, admin); r.Status != c.status {
			t.Errorf("%s %s = %d %s", c.method, c.path, r.Status, r.Body)
		}
	}
	if _, err := a.Modules.Catalog.Contract.GetService(context.Background(), uuid.New()); err == nil {
		t.Error("contract found a missing service")
	}
	if _, err := a.Modules.Catalog.Contract.GetPriceSnapshot(context.Background(), uuid.New()); err == nil {
		t.Error("contract found a missing sub-service")
	}
}

func TestCatalog_ContractAndStoreFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	svc, err := a.Modules.Catalog.Contract.GetService(ctx, catalogapp.SeedID("service", "home-salon"))
	if err != nil || !svc.WomenProvidersOnly || svc.Model != contract.ModelOnDemand || len(svc.Level2Checklist) != 2 {
		t.Fatalf("contract service: %+v %v", svc, err)
	}
	list, err := a.Modules.Catalog.Contract.ListServices(ctx)
	if err != nil || len(list) != 5 {
		t.Fatalf("list: %d %v", len(list), err)
	}
	admin := testkit.Bearer(a.Admin(t, "catalog_manager").AccessToken)
	customer := testkit.Bearer(a.SignIn(t, "01712345678", "customer").AccessToken)
	a.Do(t, "GET", "/v1/admin/catalog", nil, admin)
	a.Do(t, "GET", "/v1/customer/catalog", nil, customer)
	a.Infra.Pool.Close()
	calls := []struct {
		method, path string
		token        func(*http.Request)
		body         any
	}{
		{"GET", "/v1/customer/catalog", customer, nil},
		{"GET", "/v1/provider/catalog", customer, nil},
		{"GET", "/v1/admin/catalog", admin, nil},
		{"GET", "/v1/customer/catalog/search?q=fan", customer, nil},
		{"GET", "/v1/customer/services/" + uuid.NewString(), customer, nil},
		{"POST", "/v1/admin/catalog/categories", admin, map[string]any{"name": map[string]string{"en": "A", "bn": "B"}, "iconKey": "x"}},
		{"PUT", "/v1/admin/catalog/categories/" + uuid.NewString(), admin, map[string]any{"name": map[string]string{"en": "A", "bn": "B"}, "iconKey": "x"}},
		{"GET", "/v1/admin/catalog/sub-services/" + uuid.NewString() + "/prices", admin, nil},
	}
	for _, c := range calls {
		if r := a.Do(t, c.method, c.path, c.body, c.token); r.Status != 500 {
			t.Errorf("%s %s = %d", c.method, c.path, r.Status)
		}
	}
}
