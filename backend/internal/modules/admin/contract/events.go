package contract

import "github.com/google/uuid"

// ComplaintCreated is published when either side reports a problem (C-14).
type ComplaintCreated struct {
	ComplaintID  uuid.UUID
	TicketNumber string
	BookingID    uuid.UUID
	ReporterID   uuid.UUID
}

// EventName implements eventbus.Event.
func (ComplaintCreated) EventName() string { return "admin.ComplaintCreated" }

// ComplaintResolved is published when support resolves a complaint (A-07).
type ComplaintResolved struct {
	ComplaintID  uuid.UUID
	TicketNumber string
	BookingID    uuid.UUID
	ReporterID   uuid.UUID
	AgainstID    uuid.UUID
	Verified     bool
}

// EventName implements eventbus.Event.
func (ComplaintResolved) EventName() string { return "admin.ComplaintResolved" }

// SettingChanged is published when an admin edits a setting; the audit trail keeps
// both values.
type SettingChanged struct {
	Key     string
	Before  string
	After   string
	ActorID uuid.UUID
}

// EventName implements eventbus.Event.
func (SettingChanged) EventName() string { return "admin.SettingChanged" }
