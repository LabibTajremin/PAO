package domain

import (
	"slices"
	"time"

	"github.com/google/uuid"
)

// Status is the PRD §6.4 lifecycle.
type Status string

// Statuses.
const (
	StatusPending   Status = "pending"
	StatusActive    Status = "active"
	StatusSuspended Status = "suspended"
	StatusBanned    Status = "banned"
)

// Role names (docs/build/02-architecture.md §6).
const (
	RoleCustomer       = "customer"
	RoleProvider       = "provider"
	RoleVerifier       = "verifier"
	RoleCatalogManager = "catalog_manager"
	RoleSupportAgent   = "support_agent"
	RoleSuperAdmin     = "super_admin"
)

// AdminRoles are the roles of operations staff.
var AdminRoles = []string{RoleVerifier, RoleCatalogManager, RoleSupportAgent, RoleSuperAdmin}

// Account is one person's identity; customer and provider roles share it (PRD §3).
type Account struct {
	ID        uuid.UUID
	Phone     Phone
	Email     string
	Name      string
	Status    Status
	Roles     []string
	CreatedAt time.Time
	DeletedAt *time.Time
}

// HasRole reports whether the account holds role.
func (a Account) HasRole(role string) bool { return slices.Contains(a.Roles, role) }

// CanSignIn returns why the account may not sign in, if it may not.
func (a Account) CanSignIn() error {
	switch {
	case a.DeletedAt != nil:
		return ErrAccountDeleted
	case a.Status == StatusBanned:
		return ErrAccountBanned
	case a.Status == StatusSuspended:
		return ErrAccountSuspended
	}
	return nil
}

// RoleForApp is the role a sign-in through an app grants: the partner app makes the
// person a provider, the customer app a customer (PRD §3).
func RoleForApp(app string) string {
	if app == "partner" {
		return RoleProvider
	}
	return RoleCustomer
}

// ChangeStatus validates an admin status change. Any active or suspended account may
// be suspended, banned or reinstated; a deleted account may not change.
func (a Account) ChangeStatus(to Status) error {
	if a.DeletedAt != nil || a.Status == to {
		return ErrStatusChange
	}
	switch to {
	case StatusActive, StatusSuspended, StatusBanned:
		return nil
	}
	return ErrStatusChange
}

// IsAdminRoleSet reports whether every role is an admin role and there is at least one.
func IsAdminRoleSet(roles []string) bool {
	if len(roles) == 0 {
		return false
	}
	for _, r := range roles {
		if !slices.Contains(AdminRoles, r) {
			return false
		}
	}
	return true
}
