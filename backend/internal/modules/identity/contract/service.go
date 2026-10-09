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
}
