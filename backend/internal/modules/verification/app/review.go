package app

import (
	"context"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Status is the provider's verification screen (M14/P-03).
type Status struct {
	domain.State
	CanReceiveBookings bool
	Level2Eligible     bool
	RetryAfter         *time.Time
	NextSession        *domain.Session
}

// Status returns the provider's items, level and Level 2 situation.
func (s *Service) Status(ctx context.Context, id uuid.UUID) (Status, error) {
	st, err := s.d.Repo.Load(ctx, id)
	var rules port.Rules
	if err == nil {
		rules, err = s.d.Settings.Rules(ctx)
	}
	if err != nil {
		return Status{}, err
	}
	out := Status{State: st, CanReceiveBookings: st.CanReceiveBookings(1)}
	out.RetryAfter = domain.RetryAfter(st.Sessions, rules.Level2CoolingOff, s.d.Clock.Now())
	out.Level2Eligible = st.Level == 1 && out.RetryAfter == nil
	for i := range st.Sessions {
		if st.Sessions[i].Status == "scheduled" {
			out.NextSession = &st.Sessions[i]
		}
	}
	return out, nil
}

// Submit sends the enrolment to the review queue once every required step is done.
func (s *Service) Submit(ctx context.Context, id uuid.UUID) (Status, error) {
	err := s.d.Providers.MarkSubmitted(ctx, id)
	var p provider.Provider
	if err == nil {
		p, err = s.d.Providers.Get(ctx, id)
	}
	if err == nil {
		now := s.d.Clock.Now()
		_, err = s.d.Repo.Change(ctx, id, func(st *domain.State) ([]eventbus.Event, error) {
			st.SubmittedAt, st.ServiceIDs = &now, p.ServiceIDs
			return nil, nil
		})
	}
	if err != nil {
		return Status{}, err
	}
	return s.Status(ctx, id)
}

// QueueEntry is a queue row with the provider's name and services.
type QueueEntry struct {
	port.QueueRow
	Name     string
	Services []port.Service
	AgeHours int
}

// Queue lists submitted providers with pending items, oldest first (A-03).
func (s *Service) Queue(ctx context.Context, f port.QueueFilter, p port.Page) ([]QueueEntry, error) {
	rows, err := s.d.Repo.Queue(ctx, f, p)
	out := make([]QueueEntry, 0, len(rows))
	for _, r := range rows {
		var prov provider.Provider
		if err == nil {
			prov, err = s.d.Providers.Get(ctx, r.ProviderID)
		}
		e := QueueEntry{QueueRow: r, Name: prov.FullName, AgeHours: int(s.d.Clock.Now().Sub(r.SubmittedAt).Hours())}
		for _, id := range r.ServiceIDs {
			var svc port.Service
			if err == nil {
				svc, err = s.d.Catalog.Service(ctx, id)
				e.Services = append(e.Services, svc)
			}
		}
		out = append(out, e)
	}
	return out, err
}

// Review is everything a verifier sees for one provider (A06); the NID number is
// decrypted only here.
type Review struct {
	domain.State
	Provider  provider.Provider
	NIDNumber string
}

// Review returns the provider's profile, documents and items.
func (s *Service) Review(ctx context.Context, id uuid.UUID) (Review, error) {
	p, err := s.d.Providers.Get(ctx, id)
	var st domain.State
	if err == nil {
		st, err = s.d.Repo.Load(ctx, id)
	}
	if err != nil {
		return Review{}, err
	}
	out := Review{State: st, Provider: p}
	if st.NID != nil {
		plain, err := s.d.Cipher.Decrypt(st.NID.Ciphertext)
		if err != nil {
			return Review{}, err
		}
		out.NIDNumber = string(plain)
	}
	return out, nil
}

// Decide approves or rejects one item; the decision and any level change are audited
// through their events (PRD §6.4).
func (s *Service) Decide(ctx context.Context, id uuid.UUID, item string, actor uuid.UUID, approve bool, reason string) (Review, error) {
	reason = strings.TrimSpace(reason)
	if !approve && utf8.RuneCountInString(reason) < 3 {
		return Review{}, domain.ErrInvalid
	}
	now := s.d.Clock.Now()
	_, err := s.change(ctx, id, "review", func(st *domain.State) ([]eventbus.Event, error) {
		it := st.Item(item)
		if err := it.Decide(now, actor, approve, reason); err != nil {
			return nil, err
		}
		st.Items[item] = it
		if approve {
			return []eventbus.Event{contract.DocumentApproved{ProviderID: id, Item: contract.ItemType(item), ActorID: actor}}, nil
		}
		return []eventbus.Event{contract.DocumentRejected{ProviderID: id, Item: contract.ItemType(item), Reason: reason, ActorID: actor}}, nil
	})
	if err != nil {
		return Review{}, err
	}
	return s.Review(ctx, id)
}
