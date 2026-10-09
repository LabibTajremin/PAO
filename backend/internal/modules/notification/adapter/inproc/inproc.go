// Package inproc implements the notification contract for other modules.
package inproc

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/contract"
)

// Service adapts the notification use cases to contract.NotificationService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.NotificationService = (*Service)(nil)

// Send implements contract.NotificationService. Inbox and push are always used; SMS is
// reserved for one-time codes, which identity sends itself.
func (s *Service) Send(ctx context.Context, m contract.Message) error {
	return s.svc.Send(ctx, app.Message{Recipient: m.RecipientID, App: m.App, Template: m.Template, Data: m.Data, BookingID: m.BookingID,
		DedupeKey: m.DedupeKey, Language: string(m.Language)})
}
