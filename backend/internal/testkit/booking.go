package testkit

import (
	"net/http"
	"testing"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
)

// Party is a signed-in customer.
type Party struct {
	ID    uuid.UUID
	Token string
}

// Auth returns the customer's bearer option.
func (p Party) Auth() Request { return Bearer(p.Token) }

// Job is a booking between a verified electrician and a customer.
type Job struct {
	ID       string
	Provider ProviderSession
	Customer Party
}

// Customer signs a customer in and gives them a profile and a Banani address.
func (a *API) Customer(t testing.TB, phone string) (Party, string) {
	t.Helper()
	tp := a.SignIn(t, phone, "customer")
	c := Party{ID: tp.Account.Id, Token: tp.AccessToken}
	a.ok(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat Jahan", "language": "en"}, c.Auth())
	r := a.Do(t, "POST", "/v1/customer/addresses", map[string]any{"label": "home", "line1": "House 12, Road 5", "area": "Banani",
		"location": map[string]float64{"lat": 23.7937, "lng": 90.4066}}, c.Auth())
	if r.Status != http.StatusCreated {
		t.Fatalf("address: %d %s", r.Status, r.Body)
	}
	return c, r.JSON(t)["id"].(string)
}

// RequestedJob seeds the catalog and has a new customer request a new, online
// electrician (who must not exist yet: phones are fixed per call site).
func (a *API) RequestedJob(t testing.TB, providerPhone, customerPhone string) Job {
	t.Helper()
	a.SeedCatalog(t)
	electrician := catalogapp.SeedID("service", "electrician")
	p := a.VerifiedProvider(t, providerPhone, "male", electrician)
	a.ok(t, "POST", "/v1/provider/presence/online", map[string]any{"location": map[string]float64{"lat": 23.794, "lng": 90.407}}, p.Auth())
	c, address := a.Customer(t, customerPhone)
	body := map[string]any{"providerId": p.ID, "serviceId": electrician, "timing": "asap", "addressId": address,
		"items": []map[string]any{{"subServiceId": catalogapp.SeedID("sub-service", "fan-install"), "quantity": 1}}}
	r := a.Do(t, "POST", "/v1/customer/bookings", body, c.Auth(), Header("Idempotency-Key", "job-"+uuid.NewString()))
	if r.Status != http.StatusCreated {
		t.Fatalf("book: %d %s", r.Status, r.Body)
	}
	return Job{ID: r.JSON(t)["id"].(string), Provider: p, Customer: c}
}

// CompletedJob runs a requested job through acceptance, start and completion.
func (a *API) CompletedJob(t testing.TB, providerPhone, customerPhone string) Job {
	t.Helper()
	j := a.RequestedJob(t, providerPhone, customerPhone)
	path := "/v1/provider/jobs/" + j.ID
	a.ok(t, "POST", path+"/accept", nil, j.Provider.Auth())
	code := a.Do(t, "GET", "/v1/customer/bookings/"+j.ID+"/start-code", nil, j.Customer.Auth()).JSON(t)["code"].(string)
	a.ok(t, "POST", path+"/on-the-way", nil, j.Provider.Auth())
	a.ok(t, "POST", path+"/arrived", nil, j.Provider.Auth())
	a.ok(t, "POST", path+"/start", map[string]string{"code": code}, j.Provider.Auth())
	a.ok(t, "POST", path+"/complete", map[string]bool{"cashReceived": true}, j.Provider.Auth())
	a.RelayEvents(t)
	return j
}
