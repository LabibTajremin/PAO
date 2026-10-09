// Package postgres implements the notification repository.
package postgres

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/port"
)

// Repository stores the notification schema.
type Repository struct{ q *sqlcdb.Queries }

// New returns the repository.
func New(pool *pgxpool.Pool) *Repository { return &Repository{q: sqlcdb.New(pool)} }

// Add implements port.Repository.
func (r *Repository) Add(ctx context.Context, n domain.Notification) (bool, error) {
	rows, err := r.q.InsertNotification(ctx, sqlcdb.InsertNotificationParams{ID: n.ID, RecipientID: n.RecipientID, App: n.App, Type: n.Type,
		Title: n.Title, Body: n.Body, BookingID: n.BookingID, DedupeKey: n.DedupeKey, CreatedAt: n.CreatedAt})
	return rows == 1, err
}

// List implements port.Repository.
func (r *Repository) List(ctx context.Context, recipient uuid.UUID, app string, p port.Page) ([]domain.Notification, error) {
	rows, err := r.q.ListNotifications(ctx, sqlcdb.ListNotificationsParams{RecipientID: recipient, App: app, BeforeAt: p.At, BeforeID: p.ID,
		MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]domain.Notification, 0, len(rows))
	for _, row := range rows {
		out = append(out, domain.Notification{ID: row.ID, RecipientID: recipient, App: app, Type: row.Type, Title: row.Title, Body: row.Body,
			BookingID: row.BookingID, Read: row.ReadAt != nil, CreatedAt: row.CreatedAt})
	}
	return out, err
}

// Unread implements port.Repository.
func (r *Repository) Unread(ctx context.Context, recipient uuid.UUID, app string) (int, error) {
	n, err := r.q.CountUnread(ctx, sqlcdb.CountUnreadParams{RecipientID: recipient, App: app})
	return int(n), err
}

// MarkRead implements port.Repository.
func (r *Repository) MarkRead(ctx context.Context, recipient uuid.UUID, app string, id uuid.UUID, at time.Time) error {
	n, err := r.q.MarkRead(ctx, sqlcdb.MarkReadParams{ID: id, RecipientID: recipient, ReadAt: &at, App: app})
	if err == nil && n == 0 {
		err = domain.ErrNotFound
	}
	return err
}

// MarkAllRead implements port.Repository.
func (r *Repository) MarkAllRead(ctx context.Context, recipient uuid.UUID, app string, at time.Time) error {
	return r.q.MarkAllRead(ctx, sqlcdb.MarkAllReadParams{RecipientID: recipient, App: app, ReadAt: &at})
}

// SaveToken implements port.Repository; a token moves to whoever registered it last.
func (r *Repository) SaveToken(ctx context.Context, token string, account uuid.UUID, app, platform string, at time.Time) error {
	return r.q.UpsertToken(ctx, sqlcdb.UpsertTokenParams{Token: token, AccountID: account, App: app, Platform: platform, UpdatedAt: at})
}

// Tokens implements port.Repository.
func (r *Repository) Tokens(ctx context.Context, account uuid.UUID, app string) ([]string, error) {
	return r.q.TokensFor(ctx, sqlcdb.TokensForParams{AccountID: account, App: app})
}

// DropToken implements port.Repository.
func (r *Repository) DropToken(ctx context.Context, token string) error {
	return r.q.DeleteToken(ctx, token)
}

// Forget implements port.Repository.
func (r *Repository) Forget(ctx context.Context, account uuid.UUID) error {
	err := r.q.DeleteAccountNotifications(ctx, account)
	if err == nil {
		err = r.q.DeleteAccountTokens(ctx, account)
	}
	return err
}
