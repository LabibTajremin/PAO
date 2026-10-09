package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
)

// AddAddress implements port.Repository.
func (r *Repository) AddAddress(ctx context.Context, a domain.Address, limit int) (domain.Address, error) {
	err := r.lockedTx(ctx, a.CustomerID, func(q *sqlcdb.Queries) error {
		n, err := q.CountAddresses(ctx, a.CustomerID)
		if err == nil && n >= int64(limit) {
			err = domain.ErrAddressLimit
		}
		if err != nil {
			return err
		}
		a.Default = a.Default || n == 0
		if a.Default {
			err = q.ClearDefault(ctx, a.CustomerID)
		}
		if err == nil {
			err = q.InsertAddress(ctx, sqlcdb.InsertAddressParams{ID: a.ID, CustomerID: a.CustomerID, Label: a.Label, Line1: a.Line1,
				Line2: a.Line2, Area: a.Area, Lng: a.Location.Lng, Lat: a.Location.Lat, IsDefault: a.Default, CreatedAt: a.CreatedAt})
		}
		return err
	})
	return a, err
}

// UpdateAddress implements port.Repository. Turning the default off is not possible
// here: a customer changes the default by choosing another address.
func (r *Repository) UpdateAddress(ctx context.Context, a domain.Address) error {
	return r.lockedTx(ctx, a.CustomerID, func(q *sqlcdb.Queries) error {
		n, err := q.UpdateAddress(ctx, sqlcdb.UpdateAddressParams{ID: a.ID, CustomerID: a.CustomerID, Label: a.Label, Line1: a.Line1,
			Line2: a.Line2, Area: a.Area, Lng: a.Location.Lng, Lat: a.Location.Lat, UpdatedAt: a.UpdatedAt})
		if err == nil && n == 0 {
			err = domain.ErrAddressNotFound
		}
		if err != nil || !a.Default {
			return err
		}
		return markDefault(ctx, q, a.CustomerID, a.ID)
	})
}

func markDefault(ctx context.Context, q *sqlcdb.Queries, customerID, addressID uuid.UUID) error {
	err := q.ClearDefault(ctx, customerID)
	var n int64
	if err == nil {
		n, err = q.MarkDefault(ctx, sqlcdb.MarkDefaultParams{ID: addressID, CustomerID: customerID})
	}
	if err == nil && n == 0 {
		err = domain.ErrAddressNotFound
	}
	return err
}

// SetDefault implements port.Repository.
func (r *Repository) SetDefault(ctx context.Context, customerID, addressID uuid.UUID) error {
	return r.lockedTx(ctx, customerID, func(q *sqlcdb.Queries) error { return markDefault(ctx, q, customerID, addressID) })
}

// DeleteAddress implements port.Repository.
func (r *Repository) DeleteAddress(ctx context.Context, customerID, addressID uuid.UUID) error {
	return r.lockedTx(ctx, customerID, func(q *sqlcdb.Queries) error {
		wasDefault, err := q.DeleteAddress(ctx, sqlcdb.DeleteAddressParams{ID: addressID, CustomerID: customerID})
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.ErrAddressNotFound
		}
		if err != nil || !wasDefault {
			return err
		}
		return q.PromoteNewest(ctx, customerID)
	})
}

func toAddress(r sqlcdb.AddressByIDRow) domain.Address {
	return domain.Address{ID: r.ID, CustomerID: r.CustomerID, Label: r.Label, Line1: r.Line1, Line2: r.Line2, Area: r.Area,
		Location: domain.Point{Lat: r.Lat, Lng: r.Lng}, Default: r.IsDefault, CreatedAt: r.CreatedAt}
}

// ListAddresses implements port.Repository.
func (r *Repository) ListAddresses(ctx context.Context, customerID uuid.UUID) ([]domain.Address, error) {
	rows, err := r.q.ListAddresses(ctx, customerID)
	out := make([]domain.Address, 0, len(rows))
	for _, row := range rows {
		out = append(out, toAddress(sqlcdb.AddressByIDRow(row)))
	}
	return out, err
}

// GetAddress implements port.Repository.
func (r *Repository) GetAddress(ctx context.Context, customerID, addressID uuid.UUID) (domain.Address, error) {
	row, err := r.q.AddressByID(ctx, sqlcdb.AddressByIDParams{ID: addressID, CustomerID: customerID})
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Address{}, domain.ErrAddressNotFound
	}
	return toAddress(row), err
}
