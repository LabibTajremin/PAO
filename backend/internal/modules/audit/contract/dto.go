package contract

import (
	"time"

	"github.com/google/uuid"
)

// Entry records who did what to which subject, when and why.
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
}
