// Package contract is the identity module's public surface: the only package other
// modules may import from identity (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// IdentityService is what other modules may ask of identity.
type IdentityService interface {
	// GetAccount returns an account by ID, or ErrAccountNotFound.
	GetAccount(ctx context.Context, accountID uuid.UUID) (Account, error)
	// HasRole reports whether the account currently holds role.
	HasRole(ctx context.Context, accountID uuid.UUID, role Role) (bool, error)
	// SetAccountStatus suspends, bans or reinstates an account. Banning blocks the phone
	// number, revokes every session and publishes AccountStatusChanged (PRD §6.4).
	SetAccountStatus(ctx context.Context, in SetAccountStatusInput) (Account, error)
	// SendPhoneCode sends a one-time code to a phone that is not the caller's own
	// account, such as a provider's emergency contact (PRD §6.2 item 6).
	SendPhoneCode(ctx context.Context, phone string, purpose CodePurpose) error
	// CheckPhoneCode verifies a code sent by SendPhoneCode.
	CheckPhoneCode(ctx context.Context, phone string, purpose CodePurpose, code string) error
	// CreateAdminAccount creates an admin with a temporary password that must be changed,
	// and TOTP enrolment forced at first login (A-01).
	CreateAdminAccount(ctx context.Context, in CreateAdminInput) (AdminAccount, string, error)
	// UpdateAdminAccount changes an admin's roles or active flag and revokes sessions.
	UpdateAdminAccount(ctx context.Context, in UpdateAdminInput) (AdminAccount, error)
	// ListAdminAccounts returns every admin account.
	ListAdminAccounts(ctx context.Context) ([]AdminAccount, error)
	// ListRoles returns every role with its permissions and screens.
	ListRoles(ctx context.Context) ([]RoleDefinition, error)
	// UpdateRole replaces a role's permissions and screens and bumps the RBAC version.
	UpdateRole(ctx context.Context, in UpdateRoleInput) (RoleDefinition, error)
}
