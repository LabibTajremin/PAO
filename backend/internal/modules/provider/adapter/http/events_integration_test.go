//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	rating "github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func flagged(t *testing.T, a *testkit.API, id uuid.UUID) (bool, string) {
	t.Helper()
	var f bool
	var reason string
	if err := a.Infra.Pool.QueryRow(context.Background(), "SELECT flagged_for_review, flag_reason FROM provider.providers WHERE id = $1", id).Scan(&f, &reason); err != nil {
		t.Fatal(err)
	}
	return f, reason
}

func TestEvents_QualityFlagsAndReadModel(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	rated, _ := online(t, a, "01712345601", "male", 1, electrician)
	a.Deliver(t, rating.ReviewSubmitted{SubjectID: rated, SubjectRole: "customer", NewAverage: 1, NewCount: 50})
	a.Deliver(t, rating.ReviewSubmitted{SubjectID: rated, SubjectRole: "provider", NewAverage: 3.0, NewCount: 9})
	if f, _ := flagged(t, a, rated); f {
		t.Fatal("flagged before the minimum jobs")
	}
	a.Deliver(t, booking.BookingCompleted{Parties: booking.Parties{BookingID: uuid.New(), ProviderID: rated}})
	a.Deliver(t, rating.ReviewSubmitted{SubjectID: rated, SubjectRole: "provider", NewAverage: 3.0, NewCount: 10})
	if f, reason := flagged(t, a, rated); !f || reason != "rating_below_floor" {
		t.Fatalf("rating flag: %v %s", f, reason)
	}
	canceller, _ := online(t, a, "01712345602", "male", 1, electrician)
	for i := range 5 {
		by := "provider"
		if i == 0 {
			by = "customer"
		}
		a.Deliver(t, booking.BookingCancelled{Parties: booking.Parties{BookingID: uuid.New(), ProviderID: canceller}, By: by, AfterAcceptance: true})
	}
	if f, reason := flagged(t, a, canceller); !f || reason != "cancellations" {
		t.Fatalf("cancellation flag: %v %s", f, reason)
	}
	complained, auth := online(t, a, "01712345603", "male", 1, electrician)
	a.Deliver(t, admin.ComplaintResolved{AgainstID: complained, Verified: false})
	a.Deliver(t, admin.ComplaintResolved{AgainstID: complained, Verified: true})
	if f, reason := flagged(t, a, complained); !f || reason != "verified_complaint" {
		t.Fatalf("complaint flag: %v %s", f, reason)
	}
	a.Deliver(t, identity.AccountStatusChanged{AccountID: complained, From: identity.StatusActive, To: identity.StatusSuspended})
	if ok, _ := a.Modules.Provider.Contract.IsAvailable(ctx, complained); ok {
		t.Fatal("suspended provider online")
	}
	if r := a.Do(t, "GET", "/v1/provider/profile", nil, auth); r.JSON(t)["status"] != "suspended" || r.JSON(t)["flaggedForReview"] != true {
		t.Fatalf("profile: %s", r.Body)
	}
	a.Deliver(t, identity.AccountStatusChanged{AccountID: complained, From: identity.StatusSuspended, To: identity.StatusActive})
	a.Deliver(t, identity.AccountDeleted{AccountID: rated})
	a.Deliver(t, identity.AccountDeleted{AccountID: uuid.New()})
	if _, err := a.Modules.Provider.Contract.GetProvider(ctx, rated); err == nil {
		t.Fatal("deleted provider kept")
	}
	var jobs int
	_ = a.Infra.Pool.QueryRow(ctx, "SELECT count(*) FROM provider.outbox WHERE event_name = 'provider.ProviderFlaggedForReview'").Scan(&jobs)
	if jobs != 3 {
		t.Fatalf("flag events: %d", jobs)
	}
}

func TestEvents_BrokenPayloadsAndFailures(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	for _, name := range []string{"verification.ProviderLevelChanged", "identity.AccountStatusChanged", "identity.AccountDeleted",
		"rating.ReviewSubmitted", "booking.BookingCompleted", "booking.BookingCancelled", "admin.ComplaintResolved"} {
		if err := a.Bus.Dispatch(ctx, eventbus.Envelope{ID: uuid.New(), Name: name, Payload: []byte("{")}); err == nil {
			t.Errorf("%s accepted a broken payload", name)
		}
	}
	id, auth := online(t, a, phone, "male", 1, electrician)
	a.Deliver(t, verification.ProviderLevelChanged{ProviderID: id, From: 1, To: 0})
	if ok, _ := a.Modules.Provider.Contract.IsAvailable(ctx, id); ok {
		t.Fatal("level drop kept the provider online")
	}
	a.Infra.Redis.Del(ctx, a.Infra.Keys.Key("cache", "settings"))
	if _, err := a.Infra.Pool.Exec(ctx, "ALTER TABLE admin.settings RENAME TO gone"); err != nil {
		t.Fatal(err)
	}
	for _, e := range []eventbus.Event{
		rating.ReviewSubmitted{SubjectID: id, SubjectRole: "provider", NewAverage: 2, NewCount: 20},
		booking.BookingCancelled{Parties: booking.Parties{BookingID: uuid.New(), ProviderID: id}, By: "provider", AfterAcceptance: true},
	} {
		if err := a.Bus.Dispatch(ctx, a.Envelope(t, e)); err == nil {
			t.Errorf("%s handled without settings", e.EventName())
		}
	}
	photo := map[string]any{"language": "bn", "photoMediaId": uuid.New()}
	a.Infra.Pool.Close()
	for _, path := range []string{"/v1/provider/enrolment", "/v1/provider/profile"} {
		if r := a.Do(t, "GET", path, nil, auth); r.Status != 500 {
			t.Errorf("%s with closed pool: %d", path, r.Status)
		}
	}
	if r := a.Do(t, "PUT", "/v1/provider/profile", photo, auth); r.Status != 500 {
		t.Fatalf("photo lookup with closed pool: %d", r.Status)
	}
	a.Infra.Redis.Close()
	if err := a.Bus.Dispatch(ctx, a.Envelope(t, identity.AccountDeleted{AccountID: id})); err == nil {
		t.Fatal("deleted without a database")
	}
}
