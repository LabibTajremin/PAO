package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Schedule books a Level 2 session for a Level 1 provider outside cooling-off
// (PRD §6.3, A-04).
func (s *Service) Schedule(ctx context.Context, providerID, serviceID uuid.UUID, at time.Time, location string) (domain.Session, error) {
	location = strings.TrimSpace(location)
	if location == "" || !at.After(s.d.Clock.Now()) {
		return domain.Session{}, domain.ErrInvalid
	}
	rules, err := s.d.Settings.Rules(ctx)
	if err == nil {
		_, err = s.d.Catalog.Service(ctx, serviceID)
	}
	if err != nil {
		return domain.Session{}, err
	}
	session := domain.Session{ID: s.d.IDs.New(), ProviderID: providerID, ServiceID: serviceID, ScheduledAt: at, Location: location,
		Status: "scheduled", Checklist: []domain.CheckItem{}, Photos: []uuid.UUID{}, CreatedAt: s.d.Clock.Now()}
	_, err = s.d.Repo.Change(ctx, providerID, func(st *domain.State) ([]eventbus.Event, error) {
		if st.Level != 1 {
			return nil, domain.ErrNotEligible
		}
		if domain.RetryAfter(st.Sessions, rules.Level2CoolingOff, s.d.Clock.Now()) != nil {
			return nil, domain.ErrCoolingOff
		}
		st.Sessions = append(st.Sessions, session)
		return []eventbus.Event{contract.Level2SessionScheduled{ProviderID: providerID, SessionID: session.ID,
			ScheduledAt: at.Format(time.RFC3339), Location: location}}, nil
	})
	return session, err
}

// Sessions lists Level 2 sessions, newest first.
func (s *Service) Sessions(ctx context.Context, f port.SessionFilter, p port.Page) ([]domain.Session, error) {
	return s.d.Repo.Sessions(ctx, f, p)
}

// Session returns one session.
func (s *Service) Session(ctx context.Context, id uuid.UUID) (domain.Session, error) {
	return s.d.Repo.Session(ctx, id)
}

// RecordResult closes a session; a pass raises the provider to Level 2, a fail starts
// the cooling-off period (PRD §6.3).
func (s *Service) RecordResult(ctx context.Context, sessionID, actor uuid.UUID, o domain.Outcome) (domain.Session, error) {
	session, err := s.d.Repo.Session(ctx, sessionID)
	for _, photo := range o.Photos {
		if err == nil {
			err = s.d.Media.Attach(ctx, session.ProviderID, photo, "level2_photo")
		}
	}
	if err != nil {
		return domain.Session{}, err
	}
	now := s.d.Clock.Now()
	var out domain.Session
	_, err = s.change(ctx, session.ProviderID, "level2_"+o.Result, func(st *domain.State) ([]eventbus.Event, error) {
		cur, _ := st.Session(sessionID)
		if err := cur.Record(now, actor, o); err != nil {
			return nil, err
		}
		if o.Result == "pass" {
			st.Level2PassedAt = &now
		}
		out = *cur
		return []eventbus.Event{contract.Level2ResultRecorded{ProviderID: st.ProviderID, SessionID: sessionID, Result: o.Result, ActorID: actor}}, nil
	})
	return out, err
}
