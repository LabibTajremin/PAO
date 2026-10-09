// Package domain holds the audit entry and its rules.
package domain

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ErrInvalid is returned for an entry without an action or subject.
var ErrInvalid = errors.New("audit entry needs an action and a subject")

// Entry records who did what to which subject, when and why. Entries are never
// changed after they are written (PRD §6.4).
type Entry struct {
	ID          uuid.UUID
	At          time.Time
	ActorID     *uuid.UUID
	ActorRole   string
	Action      string
	SubjectType string
	SubjectID   string
	Reason      string
	Before      map[string]any
	After       map[string]any
	// EventID makes entries written from events idempotent.
	EventID *uuid.UUID
}

// Validate checks the required fields.
func (e Entry) Validate() error {
	if strings.TrimSpace(e.Action) == "" || strings.TrimSpace(e.SubjectType) == "" || strings.TrimSpace(e.SubjectID) == "" {
		return ErrInvalid
	}
	return nil
}

// Filter narrows the audit log (A-08).
type Filter struct {
	ActorID     *uuid.UUID
	Action      string
	SubjectType string
	SubjectID   string
	From, To    *time.Time
}
