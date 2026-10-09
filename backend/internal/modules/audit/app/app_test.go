package app

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

type memRepo struct{ entries []domain.Entry }

func (m *memRepo) Append(_ context.Context, e domain.Entry) error {
	m.entries = append(m.entries, e)
	return nil
}

func (m *memRepo) List(context.Context, domain.Filter, port.Page) ([]domain.Entry, error) {
	return m.entries, nil
}

func TestRecord_FillsIDAndTime(t *testing.T) {
	repo := &memRepo{}
	now := time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)
	s := New(repo, clock.NewFake(now), idgen.V7{})
	if err := s.Record(context.Background(), domain.Entry{Action: "x", SubjectType: "y", SubjectID: "z"}); err != nil {
		t.Fatal(err)
	}
	if repo.entries[0].ID == uuid.Nil || !repo.entries[0].At.Equal(now) {
		t.Fatalf("entry = %+v", repo.entries[0])
	}
	if err := s.Record(context.Background(), domain.Entry{}); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal("invalid entry recorded")
	}
	if list, _ := s.List(context.Background(), domain.Filter{}, port.Page{}); len(list) != 1 {
		t.Fatal("list")
	}
}

func TestHandlers_AuditEventsAndRejectBadPayloads(t *testing.T) {
	repo := &memRepo{}
	s := New(repo, clock.NewFake(time.Now()), idgen.V7{})
	actor := uuid.New()
	payloads := map[string]any{
		"identity.AccountStatusChanged":     map[string]any{"AccountID": uuid.New(), "From": "active", "To": "banned", "ActorID": actor},
		"catalog.PriceChanged":              map[string]any{"SubServiceID": uuid.New(), "AmountPaisa": 100, "ActorID": uuid.Nil},
		"verification.DocumentApproved":     map[string]any{"ProviderID": uuid.New(), "Item": "nid", "ActorID": actor},
		"verification.DocumentRejected":     map[string]any{"ProviderID": uuid.New(), "Item": "nid", "Reason": "blurred", "ActorID": actor},
		"verification.ProviderLevelChanged": map[string]any{"ProviderID": uuid.New(), "From": 0, "To": 1},
		"verification.Level2ResultRecorded": map[string]any{"ProviderID": uuid.New(), "SessionID": uuid.New(), "Result": "pass", "ActorID": actor},
		"verification.DocumentExpired":      map[string]any{"ProviderID": uuid.New(), "Item": "police_clearance"},
		"admin.SettingChanged":              map[string]any{"Key": "search.default_radius_m", "Before": "5000", "After": "6000", "ActorID": actor},
	}
	for name, h := range s.Handlers() {
		raw, _ := json.Marshal(payloads[name])
		if err := h(context.Background(), eventbus.Envelope{ID: uuid.New(), Name: name, Payload: raw, OccurredAt: time.Now()}); err != nil {
			t.Errorf("%s: %v", name, err)
		}
		if err := h(context.Background(), eventbus.Envelope{Name: name, Payload: []byte("{")}); err == nil {
			t.Errorf("%s accepted a broken payload", name)
		}
	}
	if len(repo.entries) != len(payloads) || repo.entries[0].EventID == nil {
		t.Fatalf("entries = %+v", repo.entries)
	}
}
