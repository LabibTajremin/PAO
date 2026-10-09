// Package contract is the notification module's public surface (PRD §9.3 rule 1).
package contract

import "context"

// NotificationService is what other modules may ask of the notification module.
type NotificationService interface {
	// Send renders a template in the recipient's language and delivers it on the
	// requested channels. Delivery is idempotent per (recipient, template, dedupe key).
	Send(ctx context.Context, msg Message) error
}
