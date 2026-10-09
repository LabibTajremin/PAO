// Package postgres implements the admin repository.
package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository stores the admin schema.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w}
}

func toSetting(r sqlcdb.AdminSetting) domain.Setting {
	return domain.Setting{Key: r.Key, Value: r.Value, Type: r.Type, Description: r.Description, UpdatedAt: r.UpdatedAt, UpdatedBy: r.UpdatedBy}
}

// ListSettings implements port.Repository.
func (r *Repository) ListSettings(ctx context.Context) ([]domain.Setting, error) {
	rows, err := r.q.ListSettings(ctx)
	out := make([]domain.Setting, 0, len(rows))
	for _, row := range rows {
		out = append(out, toSetting(row))
	}
	return out, err
}

// GetSetting implements port.Repository.
func (r *Repository) GetSetting(ctx context.Context, key string) (domain.Setting, error) {
	row, err := r.q.SettingByKey(ctx, key)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Setting{}, domain.ErrNotFound
	}
	return toSetting(row), err
}

// UpdateSetting implements port.Repository.
func (r *Repository) UpdateSetting(ctx context.Context, s domain.Setting, e eventbus.Event) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		err := r.q.WithTx(tx).UpdateSetting(ctx, sqlcdb.UpdateSettingParams{Key: s.Key, Value: s.Value, UpdatedAt: s.UpdatedAt, UpdatedBy: s.UpdatedBy})
		if err == nil {
			err = r.outbox.Write(ctx, tx, s.Key, e)
		}
		return err
	})
}

// CountVerifiedComplaints implements port.Repository.
func (r *Repository) CountVerifiedComplaints(ctx context.Context, againstID uuid.UUID) (int, error) {
	n, err := r.q.CountVerifiedComplaints(ctx, againstID)
	return int(n), err
}
