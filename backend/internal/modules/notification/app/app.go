// Package app holds the notification use cases: send, inbox and device tokens.
package app

import (
	"context"
	"errors"
	"log/slog"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Deps are the notification collaborators.
type Deps struct {
	Repo      port.Repository
	Pusher    port.Pusher
	Languages port.Languages
	Bookings  port.Bookings
	Clock     clock.Clock
	IDs       idgen.Generator
	Log       *slog.Logger
}

// Service implements the notification use cases.
type Service struct{ d Deps }

// New returns the notification service.
func New(d Deps) *Service { return &Service{d: d} }

// Message asks for one notification in one app.
type Message struct {
	Recipient uuid.UUID
	App       string
	Template  string
	Data      map[string]string
	BookingID *uuid.UUID
	// DedupeKey makes a redelivered event notify once.
	DedupeKey string
	// Language overrides the recipient's stored language when set.
	Language string
}

// Send stores the message in the inbox and pushes it to the recipient's devices. A
// message seen before is skipped entirely. Push failures are logged, not returned:
// the inbox entry is the record, and retrying the event would not fix a device.
func (s *Service) Send(ctx context.Context, m Message) error {
	lang := m.Language
	if lang == "" {
		lang = s.d.Languages.Language(ctx, m.Recipient, m.App)
	}
	text, err := domain.Render(m.Template, lang, m.Data)
	if err != nil || m.DedupeKey == "" || (m.App != "customer" && m.App != "partner") {
		return errors.Join(domain.ErrInvalid, err)
	}
	fresh, err := s.d.Repo.Add(ctx, domain.Notification{ID: s.d.IDs.New(), RecipientID: m.Recipient, App: m.App, Type: m.Template,
		Title: text.Title, Body: text.Body, BookingID: m.BookingID, DedupeKey: m.DedupeKey, CreatedAt: s.d.Clock.Now()})
	if err != nil || !fresh {
		return err
	}
	tokens, err := s.d.Repo.Tokens(ctx, m.Recipient, m.App)
	data := map[string]string{"type": m.Template}
	if m.BookingID != nil {
		data["bookingId"] = m.BookingID.String()
	}
	for _, t := range tokens {
		s.push(ctx, t, domain.Push{Title: text.Title, Body: text.Body, Data: data})
	}
	return err
}

func (s *Service) push(ctx context.Context, token string, p domain.Push) {
	err := s.d.Pusher.Push(ctx, token, p)
	if errors.Is(err, domain.ErrInvalidToken) {
		err = s.d.Repo.DropToken(ctx, token)
	}
	if err != nil {
		s.d.Log.WarnContext(ctx, "push failed", "error", err)
	}
}

// Inbox is a page of notifications with the unread count.
type Inbox struct {
	Items  []domain.Notification
	Unread int
}

// Inbox returns a recipient's notifications in one app, newest first.
func (s *Service) Inbox(ctx context.Context, recipient uuid.UUID, app string, p port.Page) (Inbox, error) {
	items, err := s.d.Repo.List(ctx, recipient, app, p)
	var unread int
	if err == nil {
		unread, err = s.d.Repo.Unread(ctx, recipient, app)
	}
	return Inbox{Items: items, Unread: unread}, err
}

// MarkRead marks one of the recipient's notifications read.
func (s *Service) MarkRead(ctx context.Context, recipient uuid.UUID, app string, id uuid.UUID) error {
	return s.d.Repo.MarkRead(ctx, recipient, app, id, s.d.Clock.Now())
}

// MarkAllRead marks every notification in the app read.
func (s *Service) MarkAllRead(ctx context.Context, recipient uuid.UUID, app string) error {
	return s.d.Repo.MarkAllRead(ctx, recipient, app, s.d.Clock.Now())
}

// RegisterDevice stores a push token for the app.
func (s *Service) RegisterDevice(ctx context.Context, account uuid.UUID, app, token, platform string) error {
	return s.d.Repo.SaveToken(ctx, token, account, app, platform, s.d.Clock.Now())
}

// Forget erases an account's notifications and devices.
func (s *Service) Forget(ctx context.Context, account uuid.UUID) error {
	return s.d.Repo.Forget(ctx, account)
}
