// Package peers adapts other modules' contracts to the booking ports.
package peers

import (
	"context"
	"errors"

	"github.com/google/uuid"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
)

// Catalog implements port.Catalog.
type Catalog struct{ Svc catalog.CatalogService }

// Service implements port.Catalog.
func (c Catalog) Service(ctx context.Context, id uuid.UUID) (port.Service, error) {
	s, err := c.Svc.GetService(ctx, id)
	if errors.Is(err, catalog.ErrServiceNotFound) {
		return port.Service{}, errors.Join(domain.ErrNotFound, err)
	}
	return port.Service{ID: s.ID, Name: domain.Text{EN: s.Name.EN, BN: s.Name.BN}, Model: string(s.Model), SearchRadiusM: s.SearchRadiusM,
		WomenProvidersOnly: s.WomenProvidersOnly, Published: s.Published}, err
}

// Price implements port.Catalog.
func (c Catalog) Price(ctx context.Context, id uuid.UUID) (port.Price, error) {
	p, err := c.Svc.GetPriceSnapshot(ctx, id)
	if errors.Is(err, catalog.ErrSubServiceNotFound) {
		return port.Price{}, errors.Join(domain.ErrInvalid, err)
	}
	return port.Price{SubServiceID: p.SubServiceID, ServiceID: p.ServiceID, PriceVersionID: p.PriceVersionID, Name: domain.Text{EN: p.Name.EN, BN: p.Name.BN},
		Unit: string(p.Unit), AmountPaisa: p.AmountPaisa, MaxQuantity: p.MaxQuantity, Published: p.Published}, err
}

// Customers implements port.Customers.
type Customers struct {
	Svc      customer.CustomerService
	Identity identity.IdentityService
}

// Address implements port.Customers; another customer's address is not found.
func (c Customers) Address(ctx context.Context, id, addressID uuid.UUID) (domain.Address, error) {
	a, err := c.Svc.GetAddress(ctx, id, addressID)
	if errors.Is(err, customer.ErrAddressNotFound) {
		return domain.Address{}, errors.Join(domain.ErrInvalid, err)
	}
	return domain.Address{ID: a.ID, Area: a.Area, Line1: a.Line1, Line2: a.Line2, Location: domain.Point(a.Location)}, err
}

// Customer implements port.Customers. A booking needs the customer's profile name.
func (c Customers) Customer(ctx context.Context, id, addressID uuid.UUID) (port.Customer, error) {
	cust, err := c.Svc.GetCustomer(ctx, id)
	if errors.Is(err, customer.ErrCustomerNotFound) {
		return port.Customer{}, errors.Join(domain.ErrProfileRequired, err)
	}
	var acc identity.Account
	if err == nil {
		acc, err = c.Identity.GetAccount(ctx, id)
	}
	var addr domain.Address
	if err == nil {
		addr, err = c.Address(ctx, id, addressID)
	}
	return port.Customer{Name: cust.Name, Phone: acc.Phone, Address: addr}, err
}

// Covered implements port.Customers.
func (c Customers) Covered(ctx context.Context, p domain.Point) (bool, error) {
	return c.Svc.IsInServiceArea(ctx, geo.Point(p))
}

// Providers implements port.Providers and port.Finder.
type Providers struct {
	Svc          provider.ProviderService
	Verification verification.VerificationService
}

// Provider implements port.Providers.
func (p Providers) Provider(ctx context.Context, id uuid.UUID) (port.Provider, error) {
	got, err := p.Svc.GetProvider(ctx, id)
	if errors.Is(err, provider.ErrProviderNotFound) {
		return port.Provider{}, errors.Join(domain.ErrNotBookable, err)
	}
	return port.Provider{Name: got.FullName, Phone: got.Phone, Services: got.ServiceIDs}, err
}

// IsAvailable implements port.Providers.
func (p Providers) IsAvailable(ctx context.Context, id uuid.UUID) (bool, error) {
	return p.Svc.IsAvailable(ctx, id)
}

// CanReceiveBookings implements port.Providers.
func (p Providers) CanReceiveBookings(ctx context.Context, id, service uuid.UUID) (bool, error) {
	return p.Verification.CanReceiveBookings(ctx, id, service)
}

// FindNearby implements port.Finder.
func (p Providers) FindNearby(ctx context.Context, service uuid.UUID, at domain.Point, radiusM int, womenOnly, byRating bool, limit int) ([]port.Nearby, error) {
	sort := provider.SortDistance
	if byRating {
		sort = provider.SortRating
	}
	found, err := p.Svc.FindNearby(ctx, provider.NearbyQuery{ServiceID: service, Point: geo.Point(at), RadiusM: radiusM,
		WomenProvidersOnly: womenOnly, Sort: sort, Limit: limit})
	out := make([]port.Nearby, 0, len(found))
	for _, f := range found {
		out = append(out, port.Nearby{ID: f.ProviderID, Name: f.Name, PhotoMediaID: f.PhotoMediaID, Level: f.Level, Rating: f.Rating,
			RatingCount: f.RatingCount, CompletedJobs: f.CompletedJobs, DistanceM: f.DistanceM})
	}
	return out, err
}

// Media implements port.Media.
type Media struct{ Svc media.MediaService }

// URL implements port.Media.
func (m Media) URL(ctx context.Context, viewer, id uuid.UUID) (string, error) {
	v, err := m.Svc.GetViewURL(ctx, media.ViewRequest{MediaID: id, ViewerID: viewer, ViewerRole: "customer"})
	return v.URL, err
}

// Settings implements port.Settings.
type Settings struct{ Svc admin.AdminService }

// Rules implements port.Settings.
func (s Settings) Rules(ctx context.Context) (port.Rules, error) {
	v, err := s.Svc.GetSettings(ctx)
	return port.Rules{AcceptASAP: v.AcceptTimeoutASAP, AcceptScheduled: v.AcceptTimeoutScheduled, StartCodeMaxAttempts: v.StartCodeMaxAttempts,
		StartCodeLockout: v.StartCodeLockout, DefaultRadiusM: v.DefaultSearchRadiusM}, err
}
