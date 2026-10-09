package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
)

func verified(f fixture) uuid.UUID {
	id := uuid.New()
	f.repo.rows[id] = domain.Provider{ID: id, AccountStatus: "active", Level: 1, Language: "bn", HomeBase: &dhaka, ServiceIDs: []uuid.UUID{f.electric}}
	return id
}

func TestPresence(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	id := verified(f)
	if err := f.svc.Heartbeat(ctx, id, dhaka); !errors.Is(err, domain.ErrOffline) {
		t.Fatal(err)
	}
	if err := f.svc.GoOnline(ctx, id, dhaka); err != nil {
		t.Fatal(err)
	}
	if err := f.svc.Heartbeat(ctx, id, domain.Point{Lat: 23.8, Lng: 90.42}); err != nil {
		t.Fatal(err)
	}
	if ok, _ := f.svc.IsAvailable(ctx, id); !ok {
		t.Fatal("not online")
	}
	f.presence.lost = []uuid.UUID{id}
	if err := f.svc.ReapLost(ctx); err != nil {
		t.Fatal(err)
	}
	if ok, _ := f.svc.IsAvailable(ctx, id); ok || len(f.repo.events) != 1 {
		t.Fatal("lost provider still online")
	}
	if e := f.repo.events[0].(contract.ProviderWentOffline); e.Reason != "heartbeat_lost" {
		t.Fatalf("event %+v", e)
	}
	unverified := uuid.New()
	f.repo.rows[unverified] = domain.Provider{ID: unverified, AccountStatus: "active"}
	if err := f.svc.GoOnline(ctx, unverified, dhaka); !errors.Is(err, domain.ErrNotVerified) {
		t.Fatal(err)
	}
	for _, call := range []func() error{
		func() error { return f.svc.GoOnline(ctx, uuid.New(), dhaka) },
		func() error { return f.svc.Heartbeat(ctx, uuid.New(), dhaka) },
		func() error { return f.svc.GoOffline(ctx, uuid.New(), "x") },
	} {
		if err := call(); !errors.Is(err, domain.ErrNotFound) {
			t.Fatal(err)
		}
	}
	f.presence.lost, f.presence.err = []uuid.UUID{id}, errBoom
	if err := f.svc.ReapLost(ctx); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}

func TestProfile(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	id := verified(f)
	f.peers.services[f.electric] = port.Service{ID: f.electric, Published: true}
	photo := uuid.New()
	p, err := f.svc.UpdateProfile(ctx, id, "Licensed electrician", &photo, "en")
	if err != nil || p.PhotoURL == "" || len(p.Services) != 1 || p.Bio != "Licensed electrician" {
		t.Fatalf("profile: %+v %v", p, err)
	}
	if _, err := f.svc.UpdateProfile(ctx, id, "", nil, "fr"); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	f.peers.err = errBoom
	if _, err := f.svc.UpdateProfile(ctx, id, "", &photo, "en"); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := f.svc.Profile(ctx, id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.peers.err, f.repo.err = nil, errBoom
	if _, err := f.svc.UpdateProfile(ctx, id, "", nil, "en"); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.repo.err, f.repo.getErr = nil, errBoom
	if _, err := f.svc.Profile(ctx, id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := f.svc.Get(ctx, id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}

func TestFindNearby(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	salon := uuid.New()
	f.peers.services[salon] = port.Service{ID: salon, Published: true, MinLevel: 1, WomenProvidersOnly: true}
	a, b, c, far := uuid.New(), uuid.New(), uuid.New(), uuid.New()
	f.presence.hits = []port.Hit{{ID: a, DistanceM: 300}, {ID: b, DistanceM: 900}, {ID: c, DistanceM: 1500}, {ID: far, DistanceM: 6000}}
	f.repo.candidates = []port.Candidate{
		{WorkingRadiusM: 5000, Candidate: domain.Candidate{ID: a, Gender: "male", Level: 1}},
		{WorkingRadiusM: 5000, Candidate: domain.Candidate{ID: b, Gender: "female", Level: 1}},
		{WorkingRadiusM: 5000, Candidate: domain.Candidate{ID: c, Gender: "female", Level: 2}},
		{WorkingRadiusM: 5000, Candidate: domain.Candidate{ID: far, Gender: "female", Level: 2}},
	}
	got, err := f.svc.FindNearby(ctx, Nearby{ServiceID: salon, At: dhaka, RadiusM: 10000, Limit: 5})
	if err != nil || len(got) != 2 || got[0].ID != c || got[1].ID != b || got[0].DistanceM != 1500 {
		t.Fatalf("salon: %+v %v", got, err)
	}
	got, _ = f.svc.FindNearby(ctx, Nearby{ServiceID: f.electric, At: dhaka, RadiusM: 10000, Limit: 2})
	if len(got) != 2 || got[0].ID != c || got[1].ID != a {
		t.Fatalf("electric: %+v", got)
	}
	f.presence.hits = nil
	if got, err := f.svc.FindNearby(ctx, Nearby{ServiceID: f.electric}); err != nil || len(got) != 0 {
		t.Fatal("empty")
	}
	if _, err := f.svc.FindNearby(ctx, Nearby{ServiceID: uuid.New()}); !errors.Is(err, domain.ErrUnknownService) {
		t.Fatal(err)
	}
}
