package contract

import "github.com/google/uuid"

// CatalogChanged is published after any catalog edit so caches keyed by version expire.
type CatalogChanged struct {
	Version int64
}

// EventName implements eventbus.Event.
func (CatalogChanged) EventName() string { return "catalog.CatalogChanged" }

// PriceChanged is published when a sub-service gets a new price version.
type PriceChanged struct {
	SubServiceID   uuid.UUID
	PriceVersionID uuid.UUID
	AmountPaisa    int64
	ActorID        uuid.UUID
}

// EventName implements eventbus.Event.
func (PriceChanged) EventName() string { return "catalog.PriceChanged" }
