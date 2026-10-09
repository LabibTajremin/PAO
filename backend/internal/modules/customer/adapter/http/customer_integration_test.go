//go:build integration

package http_test

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

const phone = "01712345678"

var profile = map[string]any{"name": "Nusrat Jahan", "language": "bn"}

func address(label string, isDefault bool) map[string]any {
	return map[string]any{"label": label, "line1": "House 12, Road 5", "line2": "Block C", "area": "Banani",
		"location": map[string]float64{"lat": 23.7937, "lng": 90.4066}, "isDefault": isDefault}
}

func avatar(t *testing.T, a *testkit.API, owner uuid.UUID) uuid.UUID {
	t.Helper()
	body := []byte("png")
	ticket, err := a.Modules.Media.Service.CreateUpload(context.Background(), owner, "customer", "avatar", "image/png", int64(len(body)))
	if err != nil {
		t.Fatal(err)
	}
	req, _ := http.NewRequest(http.MethodPut, ticket.URL, bytes.NewReader(body))
	for k, v := range ticket.Headers {
		req.Header.Set(k, v)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil || res.StatusCode != 200 {
		t.Fatalf("put avatar: %v %v", res, err)
	}
	_ = res.Body.Close()
	if _, err := a.Modules.Media.Contract.ConfirmUpload(context.Background(), owner, ticket.MediaID); err != nil {
		t.Fatal(err)
	}
	return ticket.MediaID
}

func TestCustomer_ProfileWithPhotoAndDeletion(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	tp := a.SignIn(t, phone, "customer")
	auth := testkit.Bearer(tp.AccessToken)
	if r := a.Do(t, "GET", "/v1/customer/profile", nil, auth); r.Code(t) != "PROFILE_NOT_FOUND" {
		t.Fatalf("no profile yet: %s", r.Body)
	}
	if r := a.Do(t, "POST", "/v1/customer/addresses", address("home", false), auth); r.Code(t) != "PROFILE_REQUIRED" {
		t.Fatalf("address before profile: %s", r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat", "language": "bn", "photoMediaId": uuid.New()}, auth); r.Code(t) != "UPLOAD_INVALID" {
		t.Fatalf("unknown photo: %s", r.Body)
	}
	photo := avatar(t, a, tp.Account.Id)
	r := a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat", "language": "en", "photoMediaId": photo}, auth)
	if r.Status != 200 || r.JSON(t)["photoUrl"] == nil || r.JSON(t)["phone"] != "+8801712345678" {
		t.Fatalf("profile: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/profile", nil, auth); r.JSON(t)["language"] != "en" {
		t.Fatalf("get profile: %s", r.Body)
	}
	other := avatar(t, a, uuid.New())
	if r := a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat", "language": "bn", "photoMediaId": other}, auth); r.Code(t) != "UPLOAD_INVALID" {
		t.Fatalf("someone else's photo: %s", r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "N", "language": "bn"}, auth); r.Status != 422 {
		t.Fatalf("short name: %d", r.Status)
	}
	a.Do(t, "POST", "/v1/customer/addresses", address("home", false), auth)
	c, err := a.Modules.Customer.Contract.GetCustomer(ctx, tp.Account.Id)
	if err != nil || c.Name != "Nusrat" || *c.PhotoMediaID != photo {
		t.Fatalf("contract: %+v %v", c, err)
	}
	a.Clock.Advance(time.Minute)
	a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone, "purpose": "delete_account"})
	if r := a.Do(t, "DELETE", "/v1/me", map[string]string{"code": a.LastCode(t, phone)}, auth); r.Status != 204 {
		t.Fatalf("delete: %d %s", r.Status, r.Body)
	}
	a.RelayEvents(t)
	if _, err := a.Modules.Customer.Contract.GetCustomer(ctx, tp.Account.Id); !errors.Is(err, contract.ErrCustomerNotFound) {
		t.Fatalf("profile survived deletion: %v", err)
	}
	var n int
	_ = a.Infra.Pool.QueryRow(ctx, "SELECT count(*) FROM customer.addresses WHERE customer_id = $1", tp.Account.Id).Scan(&n)
	if n != 0 {
		t.Fatalf("addresses survived deletion: %d", n)
	}
}

func TestCustomer_ContractAndPeerFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	if _, err := a.Modules.Customer.Contract.GetAddress(ctx, uuid.New(), uuid.New()); !errors.Is(err, contract.ErrAddressNotFound) {
		t.Fatal(err)
	}
	if ok, err := a.Modules.Customer.Contract.IsInServiceArea(ctx, geo.Point{Lat: 23.8, Lng: 90.4}); !ok || err != nil {
		t.Fatalf("empty area covers all: %v %v", ok, err)
	}
	unconfirmed, _ := a.Modules.Media.Contract.CreateUploadURL(ctx, media.UploadRequest{OwnerID: uuid.New(), Purpose: media.PurposeLevel2Photo, ContentType: "image/png", SizeBytes: 3})
	tok := testkit.Bearer(a.Token(t, uuid.New(), "customer"))
	if r := a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat", "language": "bn", "photoMediaId": unconfirmed.MediaID}, tok); r.Code(t) != "UPLOAD_INVALID" {
		t.Fatalf("level 2 photo as avatar: %s", r.Body)
	}
	id := uuid.New()
	tok = testkit.Bearer(a.Token(t, id, "customer"))
	if r := a.Do(t, "PUT", "/v1/customer/profile", profile, tok); r.Status != 500 {
		t.Fatalf("profile without account: %d %s", r.Status, r.Body)
	}
	bad := eventbus.Envelope{ID: uuid.New(), Name: "identity.AccountDeleted", Payload: []byte("{")}
	if err := a.Bus.Dispatch(ctx, bad); err == nil {
		t.Fatal("broken deletion event accepted")
	}
	a.Do(t, "PUT", "/v1/customer/profile", profile, testkit.Bearer(a.SignIn(t, phone, "customer").AccessToken))
	if _, err := a.Infra.Pool.Exec(ctx, "ALTER TABLE customer.addresses RENAME TO gone"); err != nil {
		t.Fatal(err)
	}
	signedIn := testkit.Bearer(a.SignInAgain(t, phone, "customer").AccessToken)
	if r := a.Do(t, "POST", "/v1/customer/addresses", address("home", false), signedIn); r.Status != 500 {
		t.Fatalf("address table missing: %d", r.Status)
	}
	a.Do(t, "GET", "/v1/customer/addresses", nil, tok)
	a.Infra.Redis.Del(ctx, a.Infra.Keys.Key("cache", "settings"))
	a.Infra.Pool.Close()
	for _, c := range []struct{ method, path string }{
		{"GET", "/v1/customer/addresses"}, {"GET", "/v1/customer/service-area?lat=23.8&lng=90.4"},
	} {
		if r := a.Do(t, c.method, c.path, nil, tok); r.Status != 500 {
			t.Errorf("%s %s with closed pool: %d", c.method, c.path, r.Status)
		}
	}
	if r := a.Do(t, "PUT", "/v1/customer/profile", map[string]any{"name": "Nusrat", "language": "bn", "photoMediaId": id}, tok); r.Status != 500 {
		t.Fatalf("photo lookup with closed pool: %d", r.Status)
	}
}
