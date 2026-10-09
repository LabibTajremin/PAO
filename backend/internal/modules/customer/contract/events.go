package contract

import "github.com/google/uuid"

// CustomerProfileSaved is published when a customer creates or renames their profile,
// so read models (admin search, booking snapshots) can refresh the display name.
type CustomerProfileSaved struct {
	CustomerID uuid.UUID
	Name       string
}

// EventName implements eventbus.Event.
func (CustomerProfileSaved) EventName() string { return "customer.CustomerProfileSaved" }
