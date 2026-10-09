// Package postgres implements the verification repository.
package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository stores the verification schema.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
	clock  clock.Clock
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer, clk clock.Clock) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w, clock: clk}
}

// Load implements port.Repository.
func (r *Repository) Load(ctx context.Context, id uuid.UUID) (domain.State, error) {
	lvl, err := r.q.LevelByProvider(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.NewState(id), nil
	}
	if err != nil {
		return domain.State{}, err
	}
	return load(ctx, r.q, id, levelRow(lvl))
}

// Change implements port.Repository.
func (r *Repository) Change(ctx context.Context, id uuid.UUID, fn port.Change) (domain.State, error) {
	var st domain.State
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		err := q.EnsureLevel(ctx, id)
		var lvl levelRow
		if err == nil {
			lvl, err = q.LockLevel(ctx, id)
		}
		if err == nil {
			st, err = load(ctx, q, id, lvl)
		}
		var events []eventbus.Event
		if err == nil {
			events, err = fn(&st)
		}
		if err == nil {
			err = save(ctx, q, st, r.clock.Now())
		}
		for _, e := range events {
			if err == nil {
				err = r.outbox.Write(ctx, tx, id.String(), e)
			}
		}
		return err
	})
	return st, err
}

// Levels implements port.Repository.
func (r *Repository) Levels(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]int, error) {
	rows, err := r.q.Levels(ctx, ids)
	out := make(map[uuid.UUID]int, len(rows))
	for _, row := range rows {
		out[row.ProviderID] = int(row.Level)
	}
	return out, err
}

func optional(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// Queue implements port.Repository.
func (r *Repository) Queue(ctx context.Context, f port.QueueFilter, p port.Page) ([]port.QueueRow, error) {
	rows, err := r.q.Queue(ctx, sqlcdb.QueueParams{ServiceID: f.ServiceID, ItemType: optional(f.ItemType), AfterAt: p.At, AfterID: p.ID,
		MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]port.QueueRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, port.QueueRow{ProviderID: row.ProviderID, SubmittedAt: row.SubmittedAt, PendingItems: row.PendingItems, ServiceIDs: row.ServiceIds})
	}
	return out, err
}

// Sessions implements port.Repository.
func (r *Repository) Sessions(ctx context.Context, f port.SessionFilter, p port.Page) ([]domain.Session, error) {
	rows, err := r.q.ListSessions(ctx, sqlcdb.ListSessionsParams{ProviderID: f.ProviderID, Status: optional(f.Status), BeforeAt: p.At,
		BeforeID: p.ID, MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]domain.Session, 0, len(rows))
	for _, row := range rows {
		out = append(out, toSession(row))
	}
	return out, err
}

// Session implements port.Repository.
func (r *Repository) Session(ctx context.Context, id uuid.UUID) (domain.Session, error) {
	row, err := r.q.SessionByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Session{}, domain.ErrNotFound
	}
	return toSession(row), err
}

// ExpiredBy implements port.Repository.
func (r *Repository) ExpiredBy(ctx context.Context, t time.Time) ([]uuid.UUID, error) {
	return r.q.ExpiredBy(ctx, &t)
}

// ExpiringBetween implements port.Repository.
func (r *Repository) ExpiringBetween(ctx context.Context, from, to time.Time) ([]port.ExpiringItem, error) {
	rows, err := r.q.ExpiringBetween(ctx, sqlcdb.ExpiringBetweenParams{AfterAt: &from, UntilAt: &to})
	out := make([]port.ExpiringItem, 0, len(rows))
	for _, row := range rows {
		out = append(out, port.ExpiringItem(row))
	}
	return out, err
}

// RemindOnce implements port.Repository.
func (r *Repository) RemindOnce(ctx context.Context, it port.ExpiringItem, daysBefore int, e eventbus.Event) (bool, error) {
	var sent bool
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		n, err := r.q.WithTx(tx).RecordReminder(ctx, sqlcdb.RecordReminderParams{ProviderID: it.ProviderID, ItemType: it.ItemType,
			ExpiresAt: it.ExpiresAt, DaysBefore: int32(daysBefore), SentAt: r.clock.Now()}) //nolint:gosec // 1–30 days
		sent = err == nil && n == 1
		if sent {
			err = r.outbox.Write(ctx, tx, it.ProviderID.String(), e)
		}
		return err
	})
	return sent, err
}

// NIDBlocked implements port.Repository.
func (r *Repository) NIDBlocked(ctx context.Context, hash string) (bool, error) {
	return r.q.NIDBlocked(ctx, hash)
}

// BlockNID implements port.Repository.
func (r *Repository) BlockNID(ctx context.Context, id uuid.UUID, reason string) error {
	return r.q.BlockNID(ctx, sqlcdb.BlockNIDParams{ProviderID: id, Reason: reason})
}
