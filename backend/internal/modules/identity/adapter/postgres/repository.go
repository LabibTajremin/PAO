// Package postgres implements the identity repositories on the identity schema.
package postgres

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
)

// Repository is the identity repository.
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

type accountRow struct {
	ID        uuid.UUID
	Phone     *string
	Email     *string
	Name      string
	Status    string
	CreatedAt time.Time
	DeletedAt *time.Time
	Roles     []string
}

func toAccount(r accountRow) domain.Account {
	return domain.Account{
		ID: r.ID, Phone: domain.Phone(deref(r.Phone)), Email: deref(r.Email), Name: r.Name,
		Status: domain.Status(r.Status), Roles: r.Roles, CreatedAt: r.CreatedAt, DeletedAt: r.DeletedAt,
	}
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func optional(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func notFound(err error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ErrAccountNotFound
	}
	return err
}

// AccountByID implements port.Repository.
func (r *Repository) AccountByID(ctx context.Context, id uuid.UUID) (domain.Account, error) {
	row, err := r.q.AccountByID(ctx, id)
	return toAccount(accountRow(row)), notFound(err)
}

// AccountByPhone implements port.Repository.
func (r *Repository) AccountByPhone(ctx context.Context, phone domain.Phone) (domain.Account, error) {
	row, err := r.q.AccountByPhone(ctx, optional(string(phone)))
	return toAccount(accountRow(row)), notFound(err)
}

// IsPhoneBlocked implements port.Repository.
func (r *Repository) IsPhoneBlocked(ctx context.Context, phone domain.Phone) (bool, error) {
	return r.q.IsPhoneBlocked(ctx, string(phone))
}

// ListRoles implements port.Repository.
func (r *Repository) ListRoles(ctx context.Context) ([]string, error) { return r.q.ListRoles(ctx) }

// LoadGrants implements port.Repository and rbac.Source.
func (r *Repository) LoadGrants(ctx context.Context, role string) (rbac.Grants, error) {
	perms, err := r.q.RolePermissions(ctx, role)
	if err != nil {
		return rbac.Grants{}, err
	}
	screens, err := r.q.RoleScreens(ctx, role)
	return rbac.Grants{Permissions: perms, Screens: screens}, err
}

// Catalogue implements port.Repository.
func (r *Repository) Catalogue(ctx context.Context) ([]string, []string, error) {
	perms, err := r.q.AllPermissions(ctx)
	if err != nil {
		return nil, nil, err
	}
	screens, err := r.q.AllScreens(ctx)
	return perms, screens, err
}

// InTx implements port.Repository.
func (r *Repository) InTx(ctx context.Context, fn func(tx port.TxRepository) error) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		return fn(&txRepository{q: r.q.WithTx(tx), tx: tx, outbox: r.outbox, clock: r.clock})
	})
}

func lowerEmail(s string) string { return strings.ToLower(strings.TrimSpace(s)) }
