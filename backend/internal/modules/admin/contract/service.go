// Package contract is the admin module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// AdminService is what other modules may ask of the admin module.
type AdminService interface {
	// GetSettings returns the typed platform settings (A-10), defaults filled in.
	GetSettings(ctx context.Context) (Settings, error)
	// CountVerifiedComplaints returns verified complaints against a person; they feed
	// the provider quality review (PRD §6.4).
	CountVerifiedComplaints(ctx context.Context, againstID uuid.UUID) (int, error)
}
