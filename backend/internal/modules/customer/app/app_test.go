package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

var errBoom = errors.New("boom")

type fakeRepo struct {
	customers map[uuid.UUID]domain.Customer
	addresses map[uuid.UUID]domain.Address
	err       error
}

func (f *fakeRepo) SaveCustomer(_ context.Context, c domain.Customer, _ eventbus.Event) error {
	if f.err == nil {
		f.customers[c.ID] = c
	}
	return f.err
}

func (f *fakeRepo) GetCustomer(_ context.Context, id uuid.UUID) (domain.Customer, error) {
	c, ok := f.customers[id]
	if !ok {
		return c, domain.ErrNotFound
	}
	return c, nil
}

func (f *fakeRepo) AddAddress(_ context.Context, a domain.Address, _ int) (domain.Address, error) {
	f.addresses[a.ID] = a
	return a, f.err
}

func (f *fakeRepo) UpdateAddress(_ context.Context, a domain.Address) error {
	if f.err == nil {
		f.addresses[a.ID] = a
	}
	return f.err
}

func (f *fakeRepo) SetDefault(context.Context, uuid.UUID, uuid.UUID) error    { return f.err }
func (f *fakeRepo) DeleteAddress(context.Context, uuid.UUID, uuid.UUID) error { return f.err }

func (f *fakeRepo) ListAddresses(context.Context, uuid.UUID) ([]domain.Address, error) {
	return []domain.Address{}, f.err
}

func (f *fakeRepo) GetAddress(_ context.Context, _, id uuid.UUID) (domain.Address, error) {
	return f.addresses[id], nil
}

type fakePeers struct{ mediaErr, phoneErr, areaErr error }

func (p *fakePeers) AttachAvatar(context.Context, uuid.UUID, uuid.UUID) error { return p.mediaErr }
func (p *fakePeers) URL(context.Context, uuid.UUID, uuid.UUID) (string, error) {
	return "https://photo", p.mediaErr
}
func (p *fakePeers) Phone(context.Context, uuid.UUID) (string, error) {
	return "+8801712345678", p.phoneErr
}
func (p *fakePeers) ServiceArea(context.Context) (string, error) { return "", p.areaErr }

func newService() (*Service, *fakeRepo, *fakePeers) {
	repo := &fakeRepo{customers: map[uuid.UUID]domain.Customer{}, addresses: map[uuid.UUID]domain.Address{}}
	p := &fakePeers{}
	return New(Deps{Repo: repo, Media: p, Accounts: p, Area: p, Clock: clock.NewFake(time.Now()), IDs: idgen.V7{}}), repo, p
}

var home = domain.Address{Label: "home", Line1: "House 12, Road 5", Location: domain.Point{Lat: 23.79, Lng: 90.41}}

func TestProfile(t *testing.T) {
	s, repo, p := newService()
	ctx := context.Background()
	id, photo := uuid.New(), uuid.New()
	if _, err := s.SaveProfile(ctx, domain.Customer{ID: id, Name: " x ", Language: "bn"}); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	got, err := s.SaveProfile(ctx, domain.Customer{ID: id, Name: " Nusrat ", Language: "bn", PhotoMediaID: &photo})
	if err != nil || got.Name != "Nusrat" || got.Phone == "" || got.PhotoURL == "" {
		t.Fatalf("save: %+v %v", got, err)
	}
	if c, _ := s.Customer(ctx, id); c.Name != "Nusrat" {
		t.Fatal("customer")
	}
	p.phoneErr = errBoom
	if _, err := s.Profile(ctx, id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	p.phoneErr, p.mediaErr = nil, errBoom
	if _, err := s.SaveProfile(ctx, domain.Customer{ID: id, Name: "Nusrat", Language: "bn", PhotoMediaID: &photo}); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := s.Profile(ctx, uuid.New()); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal(err)
	}
	repo.err = errBoom
	if _, err := s.SaveProfile(ctx, domain.Customer{ID: id, Name: "Nusrat", Language: "bn"}); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}

func TestAddresses(t *testing.T) {
	s, repo, p := newService()
	ctx := context.Background()
	a, err := s.AddAddress(ctx, home)
	if err != nil || a.ID == uuid.Nil {
		t.Fatal(err)
	}
	a.Line1 = "House 14, Road 5"
	if u, err := s.UpdateAddress(ctx, a); err != nil || u.Line1 != a.Line1 || u.UpdatedAt.IsZero() {
		t.Fatalf("update: %+v %v", u, err)
	}
	if _, err := s.SetDefault(ctx, a.CustomerID, a.ID); err != nil {
		t.Fatal(err)
	}
	if l, err := s.Addresses(ctx, a.CustomerID); err != nil || l == nil {
		t.Fatal(err)
	}
	if got, _ := s.Address(ctx, a.CustomerID, a.ID); got.ID != a.ID {
		t.Fatal("address")
	}
	bad := home
	bad.Label = "farm"
	if _, err := s.AddAddress(ctx, bad); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	if _, err := s.UpdateAddress(ctx, bad); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	if ok, err := s.Covered(ctx, geo.Point(home.Location)); !ok || err != nil {
		t.Fatal("covered")
	}
	repo.err, p.areaErr = errBoom, errBoom
	if _, err := s.UpdateAddress(ctx, a); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := s.SetDefault(ctx, a.CustomerID, a.ID); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if err := s.DeleteAddress(ctx, a.CustomerID, a.ID); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := s.Covered(ctx, geo.Point(home.Location)); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}
