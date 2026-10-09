package contract

import "github.com/google/uuid"

// ProviderLevelChanged is published whenever a provider's level goes up or down.
type ProviderLevelChanged struct {
	ProviderID uuid.UUID
	From       int
	To         int
	Reason     string
}

// EventName implements eventbus.Event.
func (ProviderLevelChanged) EventName() string { return "verification.ProviderLevelChanged" }

// DocumentApproved is published when a verifier approves an item.
type DocumentApproved struct {
	ProviderID uuid.UUID
	Item       ItemType
	ActorID    uuid.UUID
}

// EventName implements eventbus.Event.
func (DocumentApproved) EventName() string { return "verification.DocumentApproved" }

// DocumentRejected is published when a verifier rejects an item with a reason.
type DocumentRejected struct {
	ProviderID uuid.UUID
	Item       ItemType
	Reason     string
	ActorID    uuid.UUID
}

// EventName implements eventbus.Event.
func (DocumentRejected) EventName() string { return "verification.DocumentRejected" }

// DocumentExpired is published by the daily expiry job (PRD §6.4).
type DocumentExpired struct {
	ProviderID uuid.UUID
	Item       ItemType
}

// EventName implements eventbus.Event.
func (DocumentExpired) EventName() string { return "verification.DocumentExpired" }

// DocumentExpiring reminds a provider 30, 7 and 1 days before expiry (P-11).
type DocumentExpiring struct {
	ProviderID uuid.UUID
	Item       ItemType
	DaysLeft   int
}

// EventName implements eventbus.Event.
func (DocumentExpiring) EventName() string { return "verification.DocumentExpiring" }

// Level2SessionScheduled tells the provider when and where to attend.
type Level2SessionScheduled struct {
	ProviderID  uuid.UUID
	SessionID   uuid.UUID
	ScheduledAt string
	Location    string
}

// EventName implements eventbus.Event.
func (Level2SessionScheduled) EventName() string { return "verification.Level2SessionScheduled" }
