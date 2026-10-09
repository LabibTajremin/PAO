package app

import (
	"context"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Item is one requested sub-service.
type Item struct {
	SubServiceID uuid.UUID
	Quantity     int
}

// CreateInput is a customer's booking request.
type CreateInput struct {
	CustomerID     uuid.UUID
	ProviderID     uuid.UUID
	ServiceID      uuid.UUID
	AddressID      uuid.UUID
	Items          []Item
	ScheduledAt    *time.Time
	Note           string
	IdempotencyKey string
}

func (in CreateInput) validate(now time.Time) error {
	if strings.TrimSpace(in.IdempotencyKey) == "" || len(in.Items) == 0 || len(in.Items) > 10 || utf8.RuneCountInString(in.Note) > 500 {
		return domain.ErrInvalid
	}
	if in.ScheduledAt != nil && !in.ScheduledAt.After(now) {
		return domain.ErrInvalid
	}
	return nil
}

// lines prices the items from the current catalog; every item must belong to the
// booked service.
func (s *Service) lines(ctx context.Context, serviceID uuid.UUID, items []Item, extra bool) ([]domain.Line, error) {
	out := make([]domain.Line, 0, len(items))
	for i, it := range items {
		p, err := s.d.Catalog.Price(ctx, it.SubServiceID)
		if err == nil && (!p.Published || p.ServiceID != serviceID) {
			err = domain.ErrInvalid
		}
		var l domain.Line
		if err == nil {
			l, err = domain.NewLine(s.d.IDs.New(), p.SubServiceID, p.PriceVersionID, p.Name, p.Unit, it.Quantity, p.MaxQuantity, p.AmountPaisa)
		}
		if err != nil {
			return nil, err
		}
		l.Position, l.Extra = i, extra
		out = append(out, l)
	}
	return out, nil
}

// endsAt is the end of a duration hire: the start plus the booked hours or days.
func endsAt(svc port.Service, start time.Time, lines []domain.Line) *time.Time {
	if svc.Model != "duration_hire" {
		return nil
	}
	l := lines[0]
	end := start.Add(time.Duration(l.Quantity) * time.Hour)
	if l.Unit == "day" {
		end = start.AddDate(0, 0, l.Quantity)
	}
	return &end
}

// Create records a booking request. A repeated idempotency key returns the stored
// booking (PRD §9.6); created reports which.
func (s *Service) Create(ctx context.Context, in CreateInput) (domain.Booking, bool, error) {
	now := s.d.Clock.Now()
	if err := in.validate(now); err != nil {
		return domain.Booking{}, false, err
	}
	b, err := s.draft(ctx, in, now)
	if err != nil {
		return domain.Booking{}, false, err
	}
	return s.d.Repo.Create(ctx, b, func(b domain.Booking) eventbus.Event {
		return contract.BookingRequested{Parties: s.parties(b), AcceptDeadline: b.AcceptDeadline, Scheduled: b.Scheduled, TotalPaisa: b.TotalPaisa}
	})
}

// service returns a published, bookable service (listing and referral services are
// not booked directly).
func (s *Service) service(ctx context.Context, id uuid.UUID) (port.Service, error) {
	svc, err := s.d.Catalog.Service(ctx, id)
	if err == nil && (!svc.Published || (svc.Model != "on_demand" && svc.Model != "duration_hire")) {
		err = domain.ErrNotBookable
	}
	return svc, err
}

// sides loads both parties: the customer's address must be in the launch area and the
// provider must offer the service and be available.
func (s *Service) sides(ctx context.Context, in CreateInput) (port.Customer, port.Provider, error) {
	cust, err := s.d.Customers.Customer(ctx, in.CustomerID, in.AddressID)
	if err == nil {
		err = s.covered(ctx, cust.Address.Location)
	}
	var prov port.Provider
	if err == nil {
		prov, err = s.d.Providers.Provider(ctx, in.ProviderID)
	}
	if err == nil && !slices.Contains(prov.Services, in.ServiceID) {
		err = domain.ErrNotBookable
	}
	if err == nil {
		err = s.bookable(ctx, in.ProviderID, in.ServiceID)
	}
	return cust, prov, err
}

// draft builds the booking with every snapshot copied in (PRD §9.3 rule 4).
func (s *Service) draft(ctx context.Context, in CreateInput, now time.Time) (domain.Booking, error) {
	svc, err := s.service(ctx, in.ServiceID)
	var lines []domain.Line
	if err == nil {
		lines, err = s.lines(ctx, in.ServiceID, in.Items, false)
	}
	var cust port.Customer
	var prov port.Provider
	if err == nil {
		cust, prov, err = s.sides(ctx, in)
	}
	var rules port.Rules
	if err == nil {
		rules, err = s.d.Settings.Rules(ctx)
	}
	if err != nil {
		return domain.Booking{}, err
	}
	b := domain.Booking{ID: s.d.IDs.New(), Customer: domain.Party{ID: in.CustomerID, Name: cust.Name, Phone: cust.Phone},
		Provider: domain.Party{ID: in.ProviderID, Name: prov.Name, Phone: prov.Phone}, ServiceID: svc.ID, ServiceName: svc.Name,
		ServiceModel: svc.Model, Address: cust.Address, Note: strings.TrimSpace(in.Note), Status: domain.Requested,
		Scheduled: in.ScheduledAt != nil, ScheduledAt: in.ScheduledAt, AcceptDeadline: now.Add(rules.AcceptASAP),
		TotalPaisa: domain.Total(lines), IdempotencyKey: in.IdempotencyKey, CreatedAt: now, Lines: lines}
	start := now
	if b.Scheduled {
		b.AcceptDeadline, start = now.Add(rules.AcceptScheduled), *in.ScheduledAt
	}
	b.EndsAt = endsAt(svc, start, lines)
	e := domain.Event{ID: s.d.IDs.New(), Status: domain.Requested, Actor: domain.ByCustomer, At: now}
	b.Timeline, b.NewEvents = []domain.Event{e}, []domain.Event{e}
	return b, nil
}

// bookable checks the provider may take the service and is online (PRD §5).
func (s *Service) bookable(ctx context.Context, provider, service uuid.UUID) error {
	ok, err := s.d.Providers.CanReceiveBookings(ctx, provider, service)
	if err == nil && ok {
		ok, err = s.d.Providers.IsAvailable(ctx, provider)
	}
	if err == nil && !ok {
		err = domain.ErrNotBookable
	}
	return err
}

// covered checks the launch area (D5).
func (s *Service) covered(ctx context.Context, p domain.Point) error {
	ok, err := s.d.Customers.Covered(ctx, p)
	if err == nil && !ok {
		err = domain.ErrOutsideArea
	}
	return err
}
