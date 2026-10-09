package app

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Advance is transitions 5 (on the way) and 6 (arrived).
func (s *Service) Advance(ctx context.Context, provider, id uuid.UUID, to string) (domain.Booking, error) {
	return s.asProvider(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		if err := b.Advance(to, s.d.Clock.Now(), s.d.IDs.New()); err != nil {
			return nil, err
		}
		if to == domain.OnTheWay {
			return []eventbus.Event{contract.ProviderOnTheWay{Parties: s.parties(*b)}}, nil
		}
		return []eventbus.Event{contract.ProviderArrived{Parties: s.parties(*b)}}, nil
	})
}

// Start is transition 7. Wrong attempts are saved before the error is returned, so the
// lockout survives retries.
func (s *Service) Start(ctx context.Context, provider, id uuid.UUID, code string) (domain.Booking, error) {
	rules, err := s.d.Settings.Rules(ctx)
	var codeErr error
	var b domain.Booking
	if err != nil {
		return b, err
	}
	b, err = s.asProvider(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		codeErr = b.Start(code, s.d.Clock.Now(), s.d.IDs.New(), rules.StartCodeMaxAttempts, rules.StartCodeLockout)
		if errors.Is(codeErr, domain.ErrCodeWrong) {
			return nil, nil
		}
		if codeErr != nil {
			return nil, codeErr
		}
		return []eventbus.Event{contract.BookingStarted{Parties: s.parties(*b)}}, nil
	})
	if err == nil {
		err = codeErr
	}
	return b, err
}

// ProposeExtras adds catalog items of the booked service for the customer to approve.
func (s *Service) ProposeExtras(ctx context.Context, provider, id uuid.UUID, items []Item) (domain.Booking, error) {
	if len(items) == 0 || len(items) > 10 {
		return domain.Booking{}, domain.ErrInvalid
	}
	return s.asProvider(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		lines, err := s.lines(ctx, b.ServiceID, items, true)
		if err != nil {
			return nil, err
		}
		p := domain.Proposal{ID: s.d.IDs.New(), ProposedAt: s.d.Clock.Now(), Lines: lines}
		next := len(b.Lines)
		for _, old := range b.Proposals {
			if old.Status != "approved" {
				next += len(old.Lines)
			}
		}
		for i := range p.Lines {
			p.Lines[i].ProposalID, p.Lines[i].Position = &p.ID, next+i
		}
		if err := b.Propose(p); err != nil {
			return nil, err
		}
		added := b.Pending().AddedPaisa
		return []eventbus.Event{contract.ExtraItemsProposed{Parties: s.parties(*b), ProposalID: p.ID, AddedPaisa: added, NewTotalPaisa: b.TotalPaisa + added}}, nil
	})
}

// DecideExtras is the customer's answer to a proposal.
func (s *Service) DecideExtras(ctx context.Context, customer, id, proposal uuid.UUID, approve bool) (domain.Booking, error) {
	return s.change(ctx, id, customer, func(b *domain.Booking) ([]eventbus.Event, error) {
		if b.Customer.ID != customer {
			return nil, domain.ErrNotFound
		}
		if _, err := b.Decide(proposal, approve, s.d.Clock.Now()); err != nil {
			return nil, err
		}
		return []eventbus.Event{contract.ExtraItemsDecided{Parties: s.parties(*b), ProposalID: proposal, Approved: approve}}, nil
	})
}

// Complete is transition 8 (D4: cash confirmed).
func (s *Service) Complete(ctx context.Context, provider, id uuid.UUID, cash bool) (domain.Booking, error) {
	return s.asProvider(ctx, id, provider, func(b *domain.Booking) ([]eventbus.Event, error) {
		if err := b.Complete(cash, s.d.Clock.Now(), s.d.IDs.New()); err != nil {
			return nil, err
		}
		return []eventbus.Event{contract.BookingCompleted{Parties: s.parties(*b), TotalPaisa: b.TotalPaisa,
			CustomerName: b.Customer.Name, ProviderName: b.Provider.Name}}, nil
	})
}
