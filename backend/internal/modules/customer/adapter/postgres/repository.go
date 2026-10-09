// Package postgres implements the customer repository on PostGIS.
package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository stores the customer schema.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w}
}

// SaveCustomer implements port.Repository.
func (r *Repository) SaveCustomer(ctx context.Context, c domain.Customer, e eventbus.Event) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		err := r.q.WithTx(tx).UpsertCustomer(ctx, sqlcdb.UpsertCustomerParams{ID: c.ID, Name: c.Name, PhotoMediaID: c.PhotoMediaID,
			Language: c.Language, CreatedAt: c.UpdatedAt, Phone: c.Phone, AccountStatus: c.Status})
		if err == nil {
			err = r.outbox.Write(ctx, tx, c.ID.String(), e)
		}
		return err
	})
}

// GetCustomer implements port.Repository.
func (r *Repository) GetCustomer(ctx context.Context, id uuid.UUID) (domain.Customer, error) {
	row, err := r.q.CustomerByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Customer{}, domain.ErrNotFound
	}
	return domain.Customer{ID: row.ID, Name: row.Name, PhotoMediaID: row.PhotoMediaID, Language: row.Language, UpdatedAt: row.UpdatedAt}, err
}

// Erase deletes the customer and, by cascade, their addresses inside the caller's
// transaction (account deletion, PRD §11).
func Erase(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	return sqlcdb.New(tx).DeleteCustomer(ctx, id)
}

// lockedTx runs fn holding the customer's row lock, so limit and default checks see
// no concurrent writes.
func (r *Repository) lockedTx(ctx context.Context, customerID uuid.UUID, fn func(q *sqlcdb.Queries) error) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		_, err := q.LockCustomer(ctx, customerID)
		if errors.Is(err, pgx.ErrNoRows) {
			err = domain.ErrProfileRequired
		}
		if err == nil {
			err = fn(q)
		}
		return err
	})
}
