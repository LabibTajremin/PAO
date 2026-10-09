package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
)

// NearbyQuery is a customer's provider search (C10).
type NearbyQuery struct {
	CustomerID   uuid.UUID
	ServiceID    uuid.UUID
	SubServiceID uuid.UUID
	Quantity     int
	AddressID    *uuid.UUID
	At           *domain.Point
	ByRating     bool
	Limit        int
}

// Card is a provider in the result with a photo URL.
type Card struct {
	port.Nearby
	PhotoURL string
}

// NearbyResult is the fixed price and the providers who can do the job.
type NearbyResult struct {
	Price     domain.Line
	Providers []Card
}

func (s *Service) where(ctx context.Context, q NearbyQuery) (domain.Point, error) {
	if q.AddressID != nil {
		a, err := s.d.Customers.Address(ctx, q.CustomerID, *q.AddressID)
		return a.Location, err
	}
	if q.At == nil {
		return domain.Point{}, domain.ErrInvalid
	}
	return *q.At, nil
}

// Nearby prices the sub-service and lists verified, online providers within the
// service's radius (PRD §5).
func (s *Service) Nearby(ctx context.Context, q NearbyQuery) (NearbyResult, error) {
	svc, err := s.service(ctx, q.ServiceID)
	var lines []domain.Line
	if err == nil {
		lines, err = s.lines(ctx, q.ServiceID, []Item{{SubServiceID: q.SubServiceID, Quantity: q.Quantity}}, false)
	}
	var at domain.Point
	if err == nil {
		at, err = s.where(ctx, q)
	}
	if err == nil {
		err = s.covered(ctx, at)
	}
	var found []port.Nearby
	if err == nil {
		found, err = s.d.Finder.FindNearby(ctx, q.ServiceID, at, svc.SearchRadiusM, svc.WomenProvidersOnly, q.ByRating, q.Limit)
	}
	if err != nil {
		return NearbyResult{}, err
	}
	out := NearbyResult{Price: lines[0], Providers: make([]Card, 0, len(found))}
	for _, n := range found {
		c := Card{Nearby: n}
		// A photo that cannot be signed is left out; the card still works without it.
		if n.PhotoMediaID != nil {
			c.PhotoURL, _ = s.d.Media.URL(ctx, q.CustomerID, *n.PhotoMediaID)
		}
		out.Providers = append(out.Providers, c)
	}
	return out, nil
}
