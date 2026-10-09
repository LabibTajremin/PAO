package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// asProvider restricts a change to the booking's provider.
func (s *Service) asProvider(ctx context.Context, id, provider uuid.UUID, fn func(b *domain.Booking) ([]eventbus.Event, error)) (domain.Booking, error) {
	return s.change(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		if b.Provider.ID != provider {
			return nil, domain.ErrNotFound
		}
		return fn(b)
	})
}

// Accept is transition 1; the start code is generated now and shown only to the
// customer.
func (s *Service) Accept(ctx context.Context, provider, id uuid.UUID) (domain.Booking, error) {
	return s.asProvider(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		if err := b.Accept(s.d.Clock.Now(), s.d.IDs.New()); err != nil {
			return nil, err
		}
		b.StartCode = s.d.Code()
		return []eventbus.Event{contract.BookingAccepted{Parties: s.parties(*b)}}, nil
	})
}

// Reject is transition 2.
func (s *Service) Reject(ctx context.Context, provider, id uuid.UUID, reason string) (domain.Booking, error) {
	return s.asProvider(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		if err := b.Reject(s.d.Clock.Now(), s.d.IDs.New(), reason); err != nil {
			return nil, err
		}
		return []eventbus.Event{contract.BookingRejected{Parties: s.parties(*b), Reason: reason}}, nil
	})
}

// ExpireDue times out every request past its deadline (transition 3, D12).
func (s *Service) ExpireDue(ctx context.Context) error {
	now := s.d.Clock.Now()
	ids, err := s.d.Repo.Due(ctx, now)
	for _, id := range ids {
		if err == nil {
			_, err = s.change(ctx, id, uuid.Nil, func(b *domain.Booking) ([]eventbus.Event, error) {
				// A provider answering at the same moment already moved the booking on.
				if b.TimeOut(now, s.d.IDs.New()) != nil {
					return nil, nil
				}
				return []eventbus.Event{contract.BookingTimedOut{Parties: s.parties(*b)}}, nil
			})
		}
	}
	return err
}

// Cancel is transitions 4, 9 and 10. Reasons are stored as "reason: note".
func (s *Service) Cancel(ctx context.Context, actor string, party, id uuid.UUID, reason string) (domain.Booking, error) {
	return s.change(ctx, id, party, func(b *domain.Booking) ([]eventbus.Event, error) {
		if (actor == domain.ByCustomer) != (b.Customer.ID == party) {
			return nil, domain.ErrNotFound
		}
		if err := b.Cancel(s.d.Clock.Now(), s.d.IDs.New(), actor, reason); err != nil {
			return nil, err
		}
		return []eventbus.Event{contract.BookingCancelled{Parties: s.parties(*b), By: actor, Reason: reason, AfterAcceptance: b.AfterAcceptance()}}, nil
	})
}
