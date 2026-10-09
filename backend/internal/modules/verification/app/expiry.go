package app

import (
	"context"
	"time"

	"github.com/google/uuid"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// ReminderDays are when providers hear that a document is about to expire (P-11).
var ReminderDays = []int{30, 7, 1}

const day = 24 * time.Hour

// ExpireDocuments expires approved items past their date; the level drops and the
// provider module takes them offline (PRD §6.4).
func (s *Service) ExpireDocuments(ctx context.Context) error {
	now := s.d.Clock.Now()
	ids, err := s.d.Repo.ExpiredBy(ctx, now)
	for _, id := range ids {
		if err == nil {
			err = s.expire(ctx, id, now)
		}
	}
	return err
}

func (s *Service) expire(ctx context.Context, id uuid.UUID, now time.Time) error {
	_, err := s.change(ctx, id, "document_expired", func(st *domain.State) ([]eventbus.Event, error) {
		var events []eventbus.Event
		for t, it := range st.Items {
			if it.Expire(now) {
				st.Items[t] = it
				events = append(events, contract.DocumentExpired{ProviderID: id, Item: contract.ItemType(t)})
			}
		}
		return events, nil
	})
	return err
}

// RemindExpiring sends each reminder once per document and threshold.
func (s *Service) RemindExpiring(ctx context.Context) error {
	now := s.d.Clock.Now()
	for _, days := range ReminderDays {
		items, err := s.d.Repo.ExpiringBetween(ctx, now.Add(time.Duration(days-1)*day), now.Add(time.Duration(days)*day))
		for _, it := range items {
			if err == nil {
				e := contract.DocumentExpiring{ProviderID: it.ProviderID, Item: contract.ItemType(it.ItemType), DaysLeft: days}
				_, err = s.d.Repo.RemindOnce(ctx, it, days, e)
			}
		}
		if err != nil {
			return err
		}
	}
	return nil
}

// stepItems maps profile steps to the item they put back into review.
var stepItems = map[provider.EnrolmentStep]string{
	provider.StepPersonal: "address", provider.StepServices: "service_area", provider.StepArea: "service_area",
	provider.StepEmergencyContact: "emergency_contact", provider.StepCodeOfConduct: "code_of_conduct",
}

// OnStepSaved puts the item matching a saved profile step into review, and keeps the
// service list used by the queue filter current.
func (s *Service) OnStepSaved(ctx context.Context, id uuid.UUID, step provider.EnrolmentStep) error {
	item, ok := stepItems[step]
	if !ok {
		return nil
	}
	p, err := s.d.Providers.Get(ctx, id)
	if err != nil {
		return err
	}
	now := s.d.Clock.Now()
	_, err = s.change(ctx, id, "resubmitted", func(st *domain.State) ([]eventbus.Event, error) {
		it := st.Item(item)
		it.Submit(now, map[string]string{}, nil)
		st.Items[item], st.ServiceIDs = it, p.ServiceIDs
		// A changed name or birth date must match the NID again (PRD §6.4).
		if nid := st.Item("nid"); step == provider.StepPersonal && nid.Status != domain.Missing {
			nid.Submit(now, nid.Fields, nil)
			st.Items["nid"] = nid
		}
		return nil, nil
	})
	return err
}

// OnAccountStatus blocks suspended and banned providers; a ban also blocks their NID
// from enrolling again (PRD §6.4).
func (s *Service) OnAccountStatus(ctx context.Context, id uuid.UUID, status string) error {
	_, err := s.d.Repo.Change(ctx, id, func(st *domain.State) ([]eventbus.Event, error) {
		st.Blocked = status != "active"
		return nil, nil
	})
	if err == nil && status == "banned" {
		err = s.d.Repo.BlockNID(ctx, id, "account banned")
	}
	return err
}
