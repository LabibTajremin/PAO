//go:build integration

package http_test

import (
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

var (
	electrician = catalogapp.SeedID("service", "electrician")
	fan         = catalogapp.SeedID("sub-service", "fan-install")
	socket      = catalogapp.SeedID("sub-service", "socket-install")
	tap         = catalogapp.SeedID("sub-service", "tap-repair")
	online      = map[string]any{"location": map[string]float64{"lat": 23.7940, "lng": 90.4070}}
)

type world struct {
	a        *testkit.API
	provider testkit.ProviderSession
	customer testkit.Request
	custID   uuid.UUID
	address  string
}

// newWorld seeds the catalog and brings one verified electrician online next to a
// customer with a saved Banani address.
func newWorld(t *testing.T) world {
	t.Helper()
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	w := world{a: a}
	w.provider = a.VerifiedProvider(t, "01712345601", "male", electrician)
	if r := a.Do(t, "POST", "/v1/provider/presence/online", online, w.provider.Auth()); r.Status != 200 {
		t.Fatalf("online: %d %s", r.Status, r.Body)
	}
	tp := a.SignIn(t, "01812345602", "customer")
	w.customer, w.custID = testkit.Bearer(tp.AccessToken), tp.Account.Id
	a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat Jahan", "language": "bn"}, w.customer)
	addr := map[string]any{"label": "home", "line1": "House 12, Road 5", "area": "Banani", "location": map[string]float64{"lat": 23.7937, "lng": 90.4066}}
	w.address = a.Do(t, "POST", "/v1/customer/addresses", addr, w.customer).JSON(t)["id"].(string)
	return w
}

func (w world) body(extra map[string]any) map[string]any {
	b := map[string]any{"providerId": w.provider.ID, "serviceId": electrician, "timing": "asap", "addressId": w.address,
		"items": []map[string]any{{"subServiceId": fan, "quantity": 2}}, "note": "Second floor"}
	for k, v := range extra {
		b[k] = v
	}
	return b
}

// book creates a booking and returns its ID.
func (w world) book(t *testing.T, key string, extra map[string]any) string {
	t.Helper()
	r := w.a.Do(t, "POST", "/v1/customer/bookings", w.body(extra), w.customer, testkit.Header("Idempotency-Key", key))
	if r.Status != 201 {
		t.Fatalf("book: %d %s", r.Status, r.Body)
	}
	return r.JSON(t)["id"].(string)
}

func (w world) job(t *testing.T, id, action string, body any) testkit.Response {
	t.Helper()
	return w.a.Do(t, "POST", "/v1/provider/jobs/"+id+"/"+action, body, w.provider.Auth())
}

func (w world) appInput(service, sub uuid.UUID) app.CreateInput {
	return app.CreateInput{CustomerID: w.custID, ProviderID: w.provider.ID, ServiceID: service, AddressID: uuid.MustParse(w.address),
		Items: []app.Item{{SubServiceID: sub, Quantity: 1}}, IdempotencyKey: "booking-app-" + sub.String()}
}
