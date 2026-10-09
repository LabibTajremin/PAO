package domain

import (
	"time"

	"github.com/google/uuid"
)

// Document is an uploaded file attached to an item, e.g. kind nid_front.
type Document struct {
	ID        uuid.UUID
	ItemType  string
	Kind      string
	MediaID   uuid.UUID
	CreatedAt time.Time
}

// NIDRecord is the encrypted NID number and its keyed hash.
type NIDRecord struct {
	Ciphertext []byte
	Hash       string
}

// State is everything verification knows about one provider; changes to it are
// saved together with their events.
type State struct {
	ProviderID     uuid.UUID
	Items          map[string]Item
	Level          int
	Level2PassedAt *time.Time
	Blocked        bool
	ServiceIDs     []uuid.UUID
	SubmittedAt    *time.Time
	Sessions       []Session
	Documents      []Document
	// NewDocuments replace the current documents of their item types when saved.
	NewDocuments []Document
	// NID is the stored number; NIDChanged marks a new one to save.
	NID        *NIDRecord
	NIDChanged bool
}

// NewState returns the state of a provider verification has not seen yet.
func NewState(id uuid.UUID) State {
	return State{ProviderID: id, Items: map[string]Item{}}
}

// Item returns an item, missing when never submitted.
func (s *State) Item(t string) Item {
	if it, ok := s.Items[t]; ok {
		return it
	}
	return Item{Type: t, Status: Missing}
}

// Recalc updates the level and reports the old one when it changed.
func (s *State) Recalc() (from int, changed bool) {
	from = s.Level
	s.Level = Level(s.Items, s.Level2PassedAt != nil)
	return from, from != s.Level
}

// Session returns a session by ID.
func (s *State) Session(id uuid.UUID) (*Session, bool) {
	for i := range s.Sessions {
		if s.Sessions[i].ID == id {
			return &s.Sessions[i], true
		}
	}
	return nil, false
}

// CanReceiveBookings applies PRD §6.1/§6.4: not blocked and at least minLevel (never
// below Level 1).
func (s *State) CanReceiveBookings(minLevel int) bool {
	return !s.Blocked && s.Level >= max(1, minLevel)
}
