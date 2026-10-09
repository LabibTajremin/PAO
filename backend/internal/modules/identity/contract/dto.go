package contract

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Role is a named set of permissions (docs/build/02-architecture.md §6).
type Role string

// Roles seeded by the identity migration.
const (
	RoleCustomer       Role = "customer"
	RoleProvider       Role = "provider"
	RoleVerifier       Role = "verifier"
	RoleCatalogManager Role = "catalog_manager"
	RoleSupportAgent   Role = "support_agent"
	RoleSuperAdmin     Role = "super_admin"
)

// AccountStatus is the PRD §6.4 lifecycle: Pending → Active → Suspended → Banned.
type AccountStatus string

// Account statuses.
const (
	StatusPending   AccountStatus = "pending"
	StatusActive    AccountStatus = "active"
	StatusSuspended AccountStatus = "suspended"
	StatusBanned    AccountStatus = "banned"
)

// CodePurpose says why a one-time code was sent, so codes cannot be replayed across flows.
type CodePurpose string

// Code purposes.
const (
	PurposeLogin            CodePurpose = "login"
	PurposeDeleteAccount    CodePurpose = "delete_account"
	PurposeEmergencyContact CodePurpose = "emergency_contact"
)

// Account is the identity record shared by a person's customer and provider roles.
type Account struct {
	ID        uuid.UUID
	Phone     string
	Email     string
	Roles     []Role
	Status    AccountStatus
	CreatedAt time.Time
}

// SetAccountStatusInput describes an admin status change.
type SetAccountStatusInput struct {
	AccountID uuid.UUID
	Status    AccountStatus
	Reason    string
	ActorID   uuid.UUID
}

// AdminAccount is an operations staff member.
type AdminAccount struct {
	ID           uuid.UUID
	Email        string
	Name         string
	Roles        []Role
	Active       bool
	TOTPEnrolled bool
	LastLoginAt  *time.Time
}

// CreateAdminInput invites a new admin.
type CreateAdminInput struct {
	Email   string
	Name    string
	Roles   []Role
	ActorID uuid.UUID
}

// UpdateAdminInput changes an admin; nil fields stay unchanged.
type UpdateAdminInput struct {
	AdminID uuid.UUID
	Roles   []Role
	Active  *bool
	ActorID uuid.UUID
}

// RoleDefinition is a role with its permission and screen sets.
type RoleDefinition struct {
	Role        Role
	Permissions []string
	Screens     []string
}

// UpdateRoleInput replaces a role's permissions and screens.
type UpdateRoleInput struct {
	Role        Role
	Permissions []string
	Screens     []string
	ActorID     uuid.UUID
}

// Errors returned through the contract.
var (
	ErrAccountNotFound = errors.New("account not found")
	ErrCodeInvalid     = errors.New("one-time code invalid")
	ErrCodeExpired     = errors.New("one-time code expired")
	ErrCodeLocked      = errors.New("too many wrong codes")
	ErrRateLimited     = errors.New("too many codes requested")
	ErrEmailTaken      = errors.New("email already in use")
	ErrRoleInvalid     = errors.New("unknown role, permission or screen")
	ErrStatusInvalid   = errors.New("status change not allowed")
)
