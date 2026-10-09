package domain

import (
	"time"

	"github.com/google/uuid"
)

// CheckItem is one line of a Level 2 checklist.
type CheckItem struct {
	Item   string `json:"item"`
	Passed bool   `json:"passed"`
}

// Session is a Level 2 interview, skill test or supervised job (PRD §6.3).
type Session struct {
	ID          uuid.UUID
	ProviderID  uuid.UUID
	ServiceID   uuid.UUID
	ScheduledAt time.Time
	Location    string
	Status      string
	Result      string
	Checklist   []CheckItem
	Notes       string
	VisitLat    *float64
	VisitLng    *float64
	Photos      []uuid.UUID
	DecidedBy   *uuid.UUID
	DecidedAt   *time.Time
	CreatedAt   time.Time
}

// Outcome is a recorded Level 2 result.
type Outcome struct {
	Result    string
	Checklist []CheckItem
	Notes     string
	VisitLat  *float64
	VisitLng  *float64
	Photos    []uuid.UUID
}

// Record closes the session with a result.
func (s *Session) Record(now time.Time, actor uuid.UUID, o Outcome) error {
	if s.Status != "scheduled" {
		return ErrSessionClosed
	}
	if o.Result != "pass" && o.Result != "fail" && o.Result != "retest" {
		return ErrInvalid
	}
	s.Status, s.Result, s.Checklist, s.Notes = "completed", o.Result, o.Checklist, o.Notes
	s.VisitLat, s.VisitLng, s.Photos, s.DecidedBy, s.DecidedAt = o.VisitLat, o.VisitLng, o.Photos, &actor, &now
	return nil
}

// RetryAfter returns the end of the cooling-off period after the latest failed session,
// or nil when the provider may book a session now.
func RetryAfter(sessions []Session, coolingOff time.Duration, now time.Time) *time.Time {
	var last *time.Time
	for _, s := range sessions {
		if s.Result == "fail" && s.DecidedAt != nil && (last == nil || s.DecidedAt.After(*last)) {
			last = s.DecidedAt
		}
	}
	if last == nil {
		return nil
	}
	until := last.Add(coolingOff)
	if !until.After(now) {
		return nil
	}
	return &until
}
