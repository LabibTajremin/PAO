// Package postgres implements the media repository.
package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/media/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
)

// Repository stores media.objects rows.
type Repository struct {
	q     *sqlcdb.Queries
	clock clock.Clock
}

// New returns the repository.
func New(pool *pgxpool.Pool, clk clock.Clock) *Repository {
	return &Repository{q: sqlcdb.New(pool), clock: clk}
}

func toObject(r sqlcdb.ObjectByIDRow) domain.Object {
	return domain.Object{ID: r.ID, OwnerID: r.OwnerID, Purpose: r.Purpose, ContentType: r.ContentType, SizeBytes: r.SizeBytes,
		Bucket: r.Bucket, Key: r.ObjectKey, Confirmed: r.Status == "confirmed", Attached: r.Attached, CreatedAt: r.CreatedAt}
}

// Create implements port.Repository.
func (r *Repository) Create(ctx context.Context, o domain.Object) error {
	return r.q.CreateObject(ctx, sqlcdb.CreateObjectParams{ID: o.ID, OwnerID: o.OwnerID, Purpose: o.Purpose, ContentType: o.ContentType,
		SizeBytes: o.SizeBytes, Bucket: o.Bucket, ObjectKey: o.Key, CreatedAt: o.CreatedAt})
}

// Get implements port.Repository.
func (r *Repository) Get(ctx context.Context, id uuid.UUID) (domain.Object, error) {
	row, err := r.q.ObjectByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Object{}, domain.ErrNotFound
	}
	return toObject(row), err
}

// MarkConfirmed implements port.Repository.
func (r *Repository) MarkConfirmed(ctx context.Context, id uuid.UUID) error {
	now := r.clock.Now()
	return r.q.MarkConfirmed(ctx, sqlcdb.MarkConfirmedParams{ID: id, ConfirmedAt: &now})
}

// MarkAttached implements port.Repository.
func (r *Repository) MarkAttached(ctx context.Context, id uuid.UUID) error {
	n, err := r.q.MarkAttached(ctx, id)
	if err == nil && n == 0 {
		return domain.ErrNotFound
	}
	return err
}

// Delete implements port.Repository.
func (r *Repository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.q.DeleteObject(ctx, id)
}

// Orphans implements port.Repository.
func (r *Repository) Orphans(ctx context.Context, before time.Time) ([]domain.Object, error) {
	rows, err := r.q.Orphans(ctx, before)
	out := make([]domain.Object, 0, len(rows))
	for _, row := range rows {
		out = append(out, toObject(sqlcdb.ObjectByIDRow(row)))
	}
	return out, err
}
