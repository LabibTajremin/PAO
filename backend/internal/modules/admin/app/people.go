package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	rating "github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
)

// Console is what the admin people screens read from the modules that own the data (A-05).
type Console struct {
	Providers    provider.ProviderService
	Customers    customer.CustomerService
	Verification verification.VerificationService
	Bookings     booking.BookingService
	Ratings      rating.RatingService
	Identity     identity.IdentityService
	Audit        audit.AuditService
	Catalog      catalog.CatalogService
}

// historySize and recentSize bound the detail screens.
const (
	historySize = 50
	recentSize  = 10
)

// ProviderDetail is the admin provider record (A-05).
type ProviderDetail struct {
	Record           provider.ProviderRecord
	Profile          provider.Provider
	Services         []catalog.Service
	Items            []verification.Item
	Recent           []booking.Summary
	Complaints       int
	Cancellations30d int
	History          []audit.Entry
}

// Providers lists providers for the admin console.
func (s *Service) Providers(ctx context.Context, q provider.ProviderQuery) ([]provider.ProviderRecord, error) {
	return s.d.Console.Providers.SearchProviders(ctx, q)
}

// Services names services for provider rows; a lookup failure only drops a name.
func (s *Service) Services(ctx context.Context, ids []uuid.UUID) []catalog.Service {
	out := make([]catalog.Service, 0, len(ids))
	for _, id := range ids {
		svc, err := s.d.Console.Catalog.GetService(ctx, id)
		if err == nil {
			out = append(out, svc)
		}
	}
	return out
}

func (s *Service) providerRecord(ctx context.Context, id uuid.UUID) (provider.ProviderRecord, error) {
	list, err := s.d.Console.Providers.SearchProviders(ctx, provider.ProviderQuery{ID: &id, Limit: 1})
	if err == nil && len(list) == 0 {
		err = domain.ErrPersonNotFound
	}
	if err != nil {
		return provider.ProviderRecord{}, err
	}
	return list[0], nil
}

// ProviderDetail gathers one provider's record, verification, bookings and history.
func (s *Service) ProviderDetail(ctx context.Context, id uuid.UUID) (ProviderDetail, error) {
	rec, err := s.providerRecord(ctx, id)
	if err != nil {
		return ProviderDetail{}, err
	}
	c, d := s.d.Console, ProviderDetail{Record: rec, Services: s.Services(ctx, rec.ServiceIDs)}
	d.Profile, err = c.Providers.GetProvider(ctx, id)
	if err == nil {
		d.Items, err = c.Verification.GetItems(ctx, id)
	}
	if err == nil {
		d.Recent, err = c.Bookings.ListRecentBookings(ctx, id, recentSize)
	}
	if err == nil {
		d.Complaints, err = s.d.Repo.CountComplaintsAgainst(ctx, id)
	}
	var stats booking.ProviderStats
	if err == nil {
		stats, err = c.Bookings.GetProviderStats(ctx, id)
	}
	if err == nil {
		d.History, err = c.Audit.ListForSubject(ctx, "account", id.String(), historySize)
	}
	d.Cancellations30d = stats.Cancellations30d
	return d, err
}

// SetProviderStatus suspends, bans or reinstates a provider (A-05); identity revokes
// sessions and blocks the phone, and the status event takes them offline and blocks
// their NID (PRD §6.4).
func (s *Service) SetProviderStatus(ctx context.Context, actor, id uuid.UUID, status, reason string) (ProviderDetail, error) {
	if _, err := s.providerRecord(ctx, id); err != nil {
		return ProviderDetail{}, err
	}
	if err := s.setStatus(ctx, actor, id, status, reason); err != nil {
		return ProviderDetail{}, err
	}
	d, err := s.ProviderDetail(ctx, id)
	// The provider read model catches up from the event; show the decision at once.
	d.Record.Status = status
	if status == "active" && d.Record.Level == 0 {
		d.Record.Status = "pending"
	}
	return d, err
}

func (s *Service) setStatus(ctx context.Context, actor, id uuid.UUID, status, reason string) error {
	_, err := s.d.Console.Identity.SetAccountStatus(ctx, identity.SetAccountStatusInput{AccountID: id, Status: identity.AccountStatus(status),
		Reason: reason, ActorID: actor})
	return err
}
