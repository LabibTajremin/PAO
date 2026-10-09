// Package contract is the audit module's public surface (PRD §9.3 rule 1).
package contract

import "context"

// AuditService is what other modules may ask of the audit module.
type AuditService interface {
	// Record appends an entry. Entries can never be edited or deleted (PRD §6.4).
	Record(ctx context.Context, e Entry) error
	// ListForSubject returns the newest entries about one subject, e.g. a provider's
	// status history on the admin detail page.
	ListForSubject(ctx context.Context, subjectType, subjectID string, limit int) ([]Entry, error)
}
