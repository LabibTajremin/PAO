package contract

import "github.com/google/uuid"

// AccountCreated is published when a person signs in for the first time.
type AccountCreated struct {
	AccountID uuid.UUID
	Phone     string
	Role      Role
}

// EventName implements eventbus.Event.
func (AccountCreated) EventName() string { return "identity.AccountCreated" }

// RoleGranted is published when an existing account gains a role, e.g. a customer
// signing in to the partner app becomes a provider (PRD §3).
type RoleGranted struct {
	AccountID uuid.UUID
	Role      Role
}

// EventName implements eventbus.Event.
func (RoleGranted) EventName() string { return "identity.RoleGranted" }

// AccountStatusChanged is published on suspend, ban and reinstate.
type AccountStatusChanged struct {
	AccountID uuid.UUID
	From      AccountStatus
	To        AccountStatus
	Reason    string
	ActorID   uuid.UUID
	Roles     []Role
}

// EventName implements eventbus.Event.
func (AccountStatusChanged) EventName() string { return "identity.AccountStatusChanged" }

// AccountDeleted is published after a user deletes their account; every module erases
// the person's data when it receives it (PRD §11).
type AccountDeleted struct {
	AccountID uuid.UUID
}

// EventName implements eventbus.Event.
func (AccountDeleted) EventName() string { return "identity.AccountDeleted" }
